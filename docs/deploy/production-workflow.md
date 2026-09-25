# Workflow de producción

```text
push main → publish-ecr.yml (linux/amd64) → SSH tools → pull + migrate + smoke
```

Archivos: `.github/workflows/deploy-production.yml` + `publish-ecr.yml`  
Trigger: push a **`main`** (ignora solo docs) o Run workflow.

El VPS tools **no construye** la app. La imagen sale de ECR, igual que `lootea/backend`.

## Pasos

1. Actions asume `github-actions-ecr-push` (OIDC) y publica `lootea/chatwoot:<sha>` + alias `production` + `VERSION_CW`
2. El job de deploy pide un password ECR (12 h) y lo pasa por SSH — tools no guarda keys de AWS
3. `deploy_chatwoot.sh`: `docker login` → `git pull --ff-only main` → escribe `CHATWOOT_IMAGE` en `.env` → `compose pull` → `db:chatwoot_prepare` → `up -d --no-build`
4. Smoke `http://127.0.0.1:3000/api`
5. Si falla → restaura la URI anterior (`.chatwoot-image` o el contenedor que ya corría) y vuelve a hacer pull/`up`

Si el rollback funciona, el job queda **verde** pero con warning y `ROLLBACK_OCCURRED=1`.  
El rollback **no** revierte migraciones de DB.

Si fallan publish/pull/migrate, el script para **antes** del `up -d` de la imagen nueva cuando el pull no llegó; si `up` ya corrió, entra el rollback de imagen.

## Tags de imagen

| Tag | Mutabilidad | Uso |
|---|---|---|
| `<git sha>` | inmutable | lo que tools corre (CI inyecta esta URI) |
| `production` | móvil | alias del último deploy a main |
| `4.16.2` (`VERSION_CW`) | móvil | último build Lootea de ese upstream |

URI: `<account>.dkr.ecr.<region>.amazonaws.com/lootea/chatwoot:<tag>`

## Secrets (GitHub Actions)

Los de SSH no cambian:

| Secret | Uso |
|---|---|
| `PRODUCTION_HOST` | IP/hostname de tools |
| `PRODUCTION_USER` | Usuario SSH |
| `PRODUCTION_SSH_KEY` | Clave privada |
| `PRODUCTION_APP_PATH` | `/var/www/chatwoot` |
| `PRODUCTION_SSH_PORT` | Puerto SSH |
| `SLACK_WEBHOOK_URL` | Incoming webhook (watcher de upstream) |

Variables de repo (**las mismas que lootea-backend**):

| Variable | Ejemplo | Uso |
|---|---|---|
| `ECR_AWS_REGION` | `mx-central-1` | Región del registry |
| `ECR_PUSH_ROLE_ARN` | `arn:aws:iam::893072529062:role/github-actions-ecr-push` | OIDC push |

## Una vez en AWS (registry ya existente)

El backend ya documentó que `lootea/chatwoot` usa el mismo prefijo ECR.

1. Crear el repositorio si no existe: `lootea/chatwoot` (immutable tags, exclusiones `production`, retención ~30 imágenes).
2. En el trust de `github-actions-ecr-push`, añadir `repo:lootea/chatwoot:*` (o `ref:refs/heads/main` + `workflow_dispatch`).
3. En la policy de push, el ARN `…:repository/lootea/chatwoot`.
4. En este repo: Settings → Variables `ECR_*` + secret `SLACK_WEBHOOK_URL`.
5. Actions → deshabilitar workflows heredados de upstream (lista en [../upstream/sync-releases.md](../upstream/sync-releases.md)).

Tools no necesita AWS CLI ni usuario IAM: el password lo genera CI.

## Manual en tools (emergencia)

```bash
cd /var/www/chatwoot
export COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
# CHATWOOT_IMAGE ya está en .env tras el último deploy
$COMPOSE pull rails sidekiq
$COMPOSE up -d --no-build
```

Nunca `compose build` ni `up --build` en tools.
