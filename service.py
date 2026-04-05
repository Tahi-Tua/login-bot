import os
import hmac
import hashlib
import secrets
import sqlite3
import threading
import time
import base64
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from fastapi import FastAPI, Request
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
MAX_DEVICES_PER_KEY = int(os.environ.get("MAX_DEVICES_PER_KEY", "3"))

# Nonce store (in-memory, 2 min TTL)
nonce_store = {}
# Rate limiter store: ip -> list of timestamps
rate_store = defaultdict(list)
RATE_LIMIT = int(os.environ.get("RATE_LIMIT", "10"))  # max requests per window
RATE_WINDOW = int(os.environ.get("RATE_WINDOW", "60"))  # seconds

bot_start_lock = threading.Lock()
bot_started = False

# Initialiser le bot et l'API
bot = telebot.TeleBot(BOT_TOKEN)
app = FastAPI()

# Rate limiter helper
def _check_rate_limit(ip: str) -> bool:
    now = time.monotonic()
    attempts = rate_store[ip]
    # Purge old entries
    rate_store[ip] = [t for t in attempts if now - t < RATE_WINDOW]
    if len(rate_store[ip]) >= RATE_LIMIT:
        return False
    rate_store[ip].append(now)
    return True

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
            max_devices INTEGER NOT NULL DEFAULT 3,
            revoked INTEGER NOT NULL DEFAULT 0
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS device_activations (
            device_id TEXT NOT NULL,
            key_id TEXT NOT NULL,
            device_token TEXT NOT NULL UNIQUE,
            activated_at TEXT NOT NULL,
            revoked INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (device_id, key_id),
            FOREIGN KEY (key_id) REFERENCES keys(key_id)
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS failed_attempts (
            ip TEXT NOT NULL,
            ts TEXT NOT NULL,
            reason TEXT NOT NULL
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
def _sign(nonce: str, payload: str) -> str:
    msg = f"{nonce}:{payload}".encode()
    return base64.b64encode(hmac.new(RESPONSE_KEY, msg, hashlib.sha256).digest()).decode()

# Log failed attempt
def _log_fail(ip: str, reason: str):
    conn = sqlite3.connect(DB_PATH)
    conn.execute("INSERT INTO failed_attempts (ip, ts, reason) VALUES (?, ?, ?)",
                 (ip, datetime.now(timezone.utc).isoformat(), reason))
    conn.commit()
    conn.close()

# API nonce endpoint (challenge-response, 2 min TTL)
@app.get("/api/nonce")
def get_nonce(request: Request):
    ip = request.client.host if request.client else "unknown"
    if not _check_rate_limit(ip):
        return JSONResponse({"error": "rate_limited"}, status_code=429)

    nonce = secrets.token_hex(16)
    nonce_store[nonce] = datetime.now(timezone.utc)
    # Nettoyer les nonces expirés (> 2 min)
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=2)
    expired = [k for k, v in nonce_store.items() if v < cutoff]
    for k in expired:
        del nonce_store[k]
    return JSONResponse({"nonce": nonce})

# API pour vérifier une clé (nonce OBLIGATOIRE)
@app.get("/api/verify")
def verify_key(key: str, nonce: str, request: Request):
    ip = request.client.host if request.client else "unknown"
    if not _check_rate_limit(ip):
        return JSONResponse({"error": "rate_limited"}, status_code=429)

    # Valider le nonce (obligatoire)
    if not nonce or nonce not in nonce_store:
        _log_fail(ip, "bad_nonce")
        return JSONResponse({"status": "invalid", "reason": "bad_nonce", "sig": ""})
    del nonce_store[nonce]

    if not key.startswith("GK-"):
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "format")
        return JSONResponse({"status": "invalid", "reason": "format", "sig": sig})

    parts = key[3:].split("-", 1)
    if len(parts) != 2:
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "format")
        return JSONResponse({"status": "invalid", "reason": "format", "sig": sig})

    key_id, secret = parts
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute("SELECT secret_hash, expires_at, revoked FROM keys WHERE key_id = ?", (key_id,)).fetchone()
    conn.close()

    if not row:
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "not_found")
        return JSONResponse({"status": "invalid", "reason": "not_found", "sig": sig})

    secret_hash, expires_at, revoked = row
    if revoked:
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "revoked")
        return JSONResponse({"status": "invalid", "reason": "revoked", "sig": sig})

    if datetime.now(timezone.utc) >= datetime.fromisoformat(expires_at):
        sig = _sign(nonce, "expired")
        return JSONResponse({"status": "expired", "reason": "expired", "sig": sig})

    expected_hash = hmac.new(API_PEPPER, f"{key_id}:{secret}".encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected_hash, secret_hash):
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "bad_secret")
        return JSONResponse({"status": "invalid", "reason": "bad_secret", "sig": sig})

    sig = _sign(nonce, "valid")
    return JSONResponse({"status": "valid", "expires_at": expires_at, "sig": sig})

# API pour activer un appareil (clé + device_id -> device_token)
@app.get("/api/activate")
def activate_device(key: str, nonce: str, device_id: str, request: Request):
    ip = request.client.host if request.client else "unknown"
    if not _check_rate_limit(ip):
        return JSONResponse({"error": "rate_limited"}, status_code=429)

    # Valider le nonce
    if not nonce or nonce not in nonce_store:
        _log_fail(ip, "bad_nonce_activate")
        return JSONResponse({"status": "invalid", "reason": "bad_nonce", "sig": ""})
    del nonce_store[nonce]

    # Valider le device_id
    if not device_id or len(device_id) < 8 or len(device_id) > 128:
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "bad_device_id", "sig": sig})

    # Vérifier la clé (même logique que verify)
    if not key.startswith("GK-"):
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "format_activate")
        return JSONResponse({"status": "invalid", "reason": "format", "sig": sig})

    parts = key[3:].split("-", 1)
    if len(parts) != 2:
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "format", "sig": sig})

    key_id, secret = parts
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute("SELECT secret_hash, expires_at, revoked, max_devices FROM keys WHERE key_id = ?", (key_id,)).fetchone()

    if not row:
        conn.close()
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "not_found_activate")
        return JSONResponse({"status": "invalid", "reason": "not_found", "sig": sig})

    secret_hash, expires_at, revoked, max_devices = row

    if revoked:
        conn.close()
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "revoked", "sig": sig})

    if datetime.now(timezone.utc) >= datetime.fromisoformat(expires_at):
        conn.close()
        sig = _sign(nonce, "expired")
        return JSONResponse({"status": "expired", "reason": "expired", "sig": sig})

    expected_hash = hmac.new(API_PEPPER, f"{key_id}:{secret}".encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected_hash, secret_hash):
        conn.close()
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "bad_secret_activate")
        return JSONResponse({"status": "invalid", "reason": "bad_secret", "sig": sig})

    # Vérifier si cet appareil est déjà activé pour cette clé
    existing = conn.execute(
        "SELECT device_token, revoked FROM device_activations WHERE device_id = ? AND key_id = ?",
        (device_id, key_id)).fetchone()

    if existing:
        token, dev_revoked = existing
        if dev_revoked:
            conn.close()
            sig = _sign(nonce, "invalid")
            return JSONResponse({"status": "invalid", "reason": "device_revoked", "sig": sig})
        conn.close()
        # Renvoyer le token existant
        sig = _sign(nonce, "activated")
        return JSONResponse({"status": "activated", "device_token": token, "expires_at": expires_at, "sig": sig})

    # Vérifier le nombre d'appareils actifs pour cette clé
    count = conn.execute(
        "SELECT COUNT(*) FROM device_activations WHERE key_id = ? AND revoked = 0",
        (key_id,)).fetchone()[0]

    if count >= (max_devices or MAX_DEVICES_PER_KEY):
        conn.close()
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "max_devices", "sig": sig})

    # Créer le device_token
    device_token = secrets.token_urlsafe(32)
    conn.execute(
        "INSERT INTO device_activations (device_id, key_id, device_token, activated_at, revoked) VALUES (?, ?, ?, ?, 0)",
        (device_id, key_id, device_token, datetime.now(timezone.utc).isoformat()))
    conn.commit()
    conn.close()

    sig = _sign(nonce, "activated")
    return JSONResponse({"status": "activated", "device_token": device_token, "expires_at": expires_at, "sig": sig})

# API pour vérifier un device_token (appel périodique depuis l'app)
@app.get("/api/check")
def check_device(device_token: str, nonce: str, request: Request):
    ip = request.client.host if request.client else "unknown"
    if not _check_rate_limit(ip):
        return JSONResponse({"error": "rate_limited"}, status_code=429)

    # Valider le nonce
    if not nonce or nonce not in nonce_store:
        return JSONResponse({"status": "invalid", "reason": "bad_nonce", "sig": ""})
    del nonce_store[nonce]

    if not device_token or len(device_token) < 16:
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "bad_token", "sig": sig})

    conn = sqlite3.connect(DB_PATH)
    row = conn.execute("""
        SELECT da.revoked, k.expires_at, k.revoked
        FROM device_activations da
        JOIN keys k ON da.key_id = k.key_id
        WHERE da.device_token = ?
    """, (device_token,)).fetchone()
    conn.close()

    if not row:
        sig = _sign(nonce, "invalid")
        _log_fail(ip, "bad_device_token")
        return JSONResponse({"status": "invalid", "reason": "not_found", "sig": sig})

    dev_revoked, expires_at, key_revoked = row

    if dev_revoked or key_revoked:
        sig = _sign(nonce, "invalid")
        return JSONResponse({"status": "invalid", "reason": "revoked", "sig": sig})

    if datetime.now(timezone.utc) >= datetime.fromisoformat(expires_at):
        sig = _sign(nonce, "expired")
        return JSONResponse({"status": "expired", "reason": "expired", "sig": sig})

    sig = _sign(nonce, "valid")
    return JSONResponse({"status": "valid", "expires_at": expires_at, "sig": sig})

# Health check
@app.get("/")
def health():
    return {"status": "ok"}

# Lancer le bot Telegram en thread
def run_bot():
    bot.infinity_polling()

# Démarrer le bot au lancement de l'app uniquement si RUN_TELEGRAM_BOT=true
@app.on_event("startup")
def on_startup():
    if os.environ.get("RUN_TELEGRAM_BOT", "false").lower() != "true":
        return

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
