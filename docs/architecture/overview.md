# Arquitectura

## Stack

- `docker-compose.production.yaml` + `docker-compose.lootea.yml` → build local, imagen `lootea/chatwoot:production`
- `.env` solo en el VPS (nunca en git)
- Nginx → `127.0.0.1:3000`
- Ruta VPS: `/var/www/chatwoot`, rama `main`

## Ramas

```text
upstream tag → develop → main → GitHub Actions → VPS
```

## Remotes

| Remote | Repo |
|---|---|
| `origin` | lootea/chatwoot |
| `upstream` | chatwoot/chatwoot (solo fetch/merge de tags) |
