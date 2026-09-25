# Operación diaria

VPS tools siempre en rama **`main`**. Imagen = `CHATWOOT_IMAGE` en `.env`.

```bash
export COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
cd /var/www/chatwoot
```

## Comandos

```bash
$COMPOSE ps
$COMPOSE logs -f --tail=100 rails
$COMPOSE logs -f --tail=100 sidekiq
$COMPOSE restart rails sidekiq
$COMPOSE run --rm rails bundle exec rails c
cat .chatwoot-image   # URI ECR del último smoke OK
```

Nunca `$COMPOSE build` ni `up --build`.

## Backup Postgres

```bash
$COMPOSE exec postgres pg_dump -U postgres chatwoot > chatwoot-$(date +%F).sql
```

## Post-deploy

- Job verde en Actions (warning/`ROLLBACK_OCCURRED=1` = rollback de imagen, revisar DB)
- `$COMPOSE ps` OK y el contenedor usa un URI `*.dkr.ecr.* /lootea/chatwoot:<sha>`
- `https://support.lootea.com.mx` responde
