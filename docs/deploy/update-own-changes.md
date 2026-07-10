# Actualizar cambios propios

```text
develop → merge a main → push → Actions despliega
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

El workflow **Deploy Production** corre solo. Redeploy manual: Actions → Run workflow.

## Fallback manual (VPS)

```bash
cd /var/www/chatwoot
export COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
git pull --ff-only origin main
$COMPOSE build
$COMPOSE run --rm rails bundle exec rails db:chatwoot_prepare
$COMPOSE up -d
```

Solo `.env` en el servidor: editar y `$COMPOSE up -d --force-recreate rails sidekiq`.
