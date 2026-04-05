import os
import hmac
import hashlib
import secrets
import sqlite3
import threading
import base64
from datetime import datetime, timedelta, timezone
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import uvicorn

# Variables d'environnement (configurées dans Render Dashboard)
BOT_TOKEN = os.environ["BOT_TOKEN"]
ADMIN_IDS = {
    int(value.strip())
    for value in os.environ.get("ADMIN_IDS", "").split(",")
    if value.strip()
}
API_PEPPER = os.environ.get("API_PEPPER", "change_me").encode()
RESPONSE_KEY = os.environ.get("RESPONSE_KEY", "Xk9#mW2$pL7@nQ4!").encode()
DB_PATH = os.environ.get("DB_PATH", "keys.db")
DB_DIR = os.path.dirname(DB_PATH)

# Nonce store (in-memory, 5 min TTL)
nonce_store = {}
bot_start_lock = threading.Lock()
bot_started = False

# Initialiser le bot et l'API
bot = telebot.TeleBot(BOT_TOKEN)
app = FastAPI()

# Initialiser la base de données SQLite
def init_db():
    if DB_DIR:
        os.makedirs(DB_DIR, exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS keys (
            key_id TEXT PRIMARY KEY,
            secret_hash TEXT NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            revoked INTEGER NOT NULL DEFAULT 0
        )
    """)
    conn.commit()
    conn.close()

init_db()

# Durées disponibles
KEY_DURATIONS = {
    "test": {"label": "Test (1 jour)", "days": 1},
    "vip": {"label": "VIP (1 mois)", "days": 30},
    "lifetime": {"label": "LifeTime (Illimité)", "days": None},
}

# Fonction pour générer une clé
def generate_key(duration_type: str):
    key_id = secrets.token_hex(4).upper()
    secret = secrets.token_urlsafe(16)
    full_key = f"GK-{key_id}-{secret}"

    dur = KEY_DURATIONS[duration_type]
    if dur["days"] is None:
        expires_at = "9999-12-31T23:59:59+00:00"
    else:
        expires_at = (datetime.now(timezone.utc) + timedelta(days=dur["days"])).isoformat()

    secret_hash = hmac.new(API_PEPPER, f"{key_id}:{secret}".encode(), hashlib.sha256).hexdigest()

    conn = sqlite3.connect(DB_PATH)
    conn.execute("INSERT INTO keys (key_id, secret_hash, created_at, expires_at, revoked) VALUES (?, ?, ?, ?, 0)",
                 (key_id, secret_hash, datetime.now(timezone.utc).isoformat(), expires_at))
    conn.commit()
    conn.close()

    return full_key, expires_at, dur["label"]

# Commande Telegram pour créer une clé
@bot.message_handler(commands=["newkey"])
def handle_newkey(message):
    if message.from_user.id not in ADMIN_IDS:
        bot.reply_to(message, "Accès refusé.")
        return

    markup = InlineKeyboardMarkup(row_width=1)
    markup.add(
        InlineKeyboardButton("🧪 Test (1 jour)", callback_data="newkey_test"),
        InlineKeyboardButton("⭐ VIP (1 mois)", callback_data="newkey_vip"),
        InlineKeyboardButton("♾️ LifeTime (Illimité)", callback_data="newkey_lifetime"),
    )
    bot.reply_to(message, "Choisissez la durée de la clé :", reply_markup=markup)

# Callback quand l'admin clique sur un bouton de durée
@bot.callback_query_handler(func=lambda call: call.data.startswith("newkey_"))
def handle_newkey_callback(call):
    if call.from_user.id not in ADMIN_IDS:
        bot.answer_callback_query(call.id, "Accès refusé.")
        return

    duration_type = call.data.replace("newkey_", "")
    if duration_type not in KEY_DURATIONS:
        bot.answer_callback_query(call.id, "Durée invalide.")
        return

    key, expires_at, label = generate_key(duration_type)

    if duration_type == "lifetime":
        expire_text = "Jamais"
    else:
        expire_text = datetime.fromisoformat(expires_at).strftime("%d/%m/%y")

    bot.answer_callback_query(call.id, "Clé générée !")
    bot.edit_message_text(
        f"🔑 *Clé générée* — {label}\n\n"
        f"`{key}`\n\n"
        f"📅 Expire le : *{expire_text}*",
        chat_id=call.message.chat.id,
        message_id=call.message.message_id,
        parse_mode="Markdown"
    )

# Helper: signer la réponse avec HMAC-SHA256
def _sign(nonce: str, status: str) -> str:
    msg = f"{nonce}:{status}".encode()
    return base64.b64encode(hmac.new(RESPONSE_KEY, msg, hashlib.sha256).digest()).decode()

# API nonce endpoint (challenge-response)
@app.get("/api/nonce")
def get_nonce():
    nonce = secrets.token_hex(16)
    nonce_store[nonce] = datetime.now(timezone.utc)
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=5)
    expired = [k for k, v in nonce_store.items() if v < cutoff]
    for k in expired:
        del nonce_store[k]
    return JSONResponse({"nonce": nonce})

# API pour vérifier une clé (avec nonce + signature HMAC)
@app.get("/api/verify")
def verify_key(key: str, nonce: str = ""):
    if nonce:
        if nonce not in nonce_store:
            return JSONResponse({"status": "invalid", "reason": "bad_nonce", "sig": ""})
        del nonce_store[nonce]

    if not key.startswith("GK-"):
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "format", "sig": sig})

    parts = key[3:].split("-", 1)
    if len(parts) != 2:
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "format", "sig": sig})

    key_id, secret = parts
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute("SELECT secret_hash, expires_at, revoked FROM keys WHERE key_id = ?", (key_id,)).fetchone()
    conn.close()

    if not row:
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "not_found", "sig": sig})

    secret_hash, expires_at, revoked = row
    if revoked:
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "revoked", "sig": sig})

    if datetime.now(timezone.utc) >= datetime.fromisoformat(expires_at):
        sig = _sign(nonce, "expired")
        return JSONResponse({"status": "expired", "reason": "expired", "sig": sig})

    expected_hash = hmac.new(API_PEPPER, f"{key_id}:{secret}".encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected_hash, secret_hash):
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "bad_secret", "sig": sig})

    sig = _sign(nonce, "valid")
    return JSONResponse({"status": "valid", "expires_at": expires_at, "sig": sig})

# Health check
@app.get("/")
def health():
    return {"status": "ok"}

# Lancer le bot Telegram en thread
def run_bot():
    bot.infinity_polling()

# Démarrer le bot au lancement de l'app (fonctionne avec uvicorn CLI et __main__)
@app.on_event("startup")
def on_startup():
    global bot_started

    with bot_start_lock:
        if bot_started:
            return

        threading.Thread(target=run_bot, daemon=True).start()
        bot_started = True

# Point d'entrée local
if __name__ == "__main__":
    port = int(os.environ.get("PORT", "10000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
