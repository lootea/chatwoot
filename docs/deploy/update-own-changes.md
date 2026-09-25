# Actualizar cambios propios

```text
develop → merge a main → push → Actions publica imagen → tools pull
```

## Desarrollo

```bash
git checkout develop && git pull origin develop
git push origin develop
```

## Producción

```bash
git checkout main && git pull origin main
git merge develop
git push origin main
```

El workflow **Deploy Production** corre solo (publish ECR + pull). Redeploy de un SHA ya publicado: Actions → Run workflow (vuelve a mover el alias `production` y tools hace pull).

## Fallback manual (tools)

```bash
cd /var/www/chatwoot
export COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
git pull --ff-only origin main
# CHATWOOT_IMAGE en .env; no construir
$COMPOSE pull rails sidekiq
$COMPOSE run --rm rails bundle exec rails db:chatwoot_prepare
$COMPOSE up -d --no-build
```

Solo `.env` en el servidor (SMTP, etc.): editar y `$COMPOSE up -d --force-recreate --no-build rails sidekiq`.
