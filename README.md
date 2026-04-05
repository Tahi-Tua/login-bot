# login-bot

Backend FastAPI + bot Telegram pour la generation et la validation de cles.

## Deploiement Render

Type de service: Web Service Python

Build Command:

```bash
pip install -r requirements.txt
```

Start Command:

```bash
uvicorn service:app --host 0.0.0.0 --port $PORT
```

## Variables d'environnement

Configure ces variables dans Render:

- BOT_TOKEN
- ADMIN_IDS
- API_PEPPER
- RESPONSE_KEY
- DB_PATH

Exemple de DB_PATH avec disque persistant Render:

```text
/opt/render/project/src/data/keys.db
```

## Disque persistant Render

SQLite ne doit pas utiliser le filesystem ephemere. Ajoute un disque persistant sur Render et pointe DB_PATH vers un chemin situe sur ce disque.

## Endpoints

- GET /
- GET /api/nonce
- GET /api/verify?key=...&nonce=...

## Notes

Le bot Telegram est demarre dans un thread au startup de l'application FastAPI.
