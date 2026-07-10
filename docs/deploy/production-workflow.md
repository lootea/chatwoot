# Workflow de producción

Archivo: `.github/workflows/deploy-production.yml`  
Trigger: push a **`main`** (o Run workflow).

## Pasos

1. Guarda imagen actual como `lootea/chatwoot:previous`
2. `git pull` → `build` → `db:chatwoot_prepare` → `up -d`
3. Smoke check `/api`
4. Si falla → restaura `:previous` y vuelve a hacer `up -d`

Si el rollback funciona, el job queda **verde** pero con warning y `ROLLBACK_OCCURRED=1` en el log.  
El rollback **no** revierte migraciones de DB.

Si fallan pull/build/migrate, el script para **antes** del `up -d` (contenedores viejos siguen).

## Secrets (GitHub Actions)

| Secret | Uso |
|---|---|
| `PRODUCTION_HOST` | IP/hostname |
| `PRODUCTION_USER` | Usuario SSH |
| `PRODUCTION_SSH_KEY` | Clave privada |
| `PRODUCTION_APP_PATH` | `/var/www/chatwoot` |
| `PRODUCTION_SSH_PORT` | Puerto SSH |

VPS: usuario con Docker + `git pull` sin password (deploy key). Pública de la clave SSH en `authorized_keys`.
