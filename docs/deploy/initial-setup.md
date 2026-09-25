# Setup inicial

VPS **tools**, Docker, rama **`main`**. La imagen **no** se construye aquí: sale de ECR.

## Una vez en AWS + GitHub

Ver [production-workflow.md](production-workflow.md) (repo ECR `lootea/chatwoot`, OIDC, variables `ECR_*`).

Publicar la primera imagen: Actions → **Publish ECR image** (o el primer push a `main`).

## Clone

```bash
sudo mkdir -p /var/www && cd /var/www
sudo git clone -b main https://github.com/lootea/chatwoot.git chatwoot
cd /var/www/chatwoot
cp .env.example .env && chmod 600 .env
```

Añadir al `.env` la URI publicada (CI lo reescribe en cada deploy):

```env
CHATWOOT_IMAGE=<account>.dkr.ecr.<region>.amazonaws.com/lootea/chatwoot:<sha>
```

## `.env` mínimo

| Variable | Valor |
|---|---|
| `CHATWOOT_IMAGE` | URI ECR del primer publish |
| `FRONTEND_URL` | `https://support.lootea.com.mx` |
| `FORCE_SSL` | `true` |
| `SECRET_KEY_BASE` | `openssl rand -hex 64` |
| `RAILS_ENV` | `production` |
| `POSTGRES_*` | host `postgres`, user `postgres`, db `chatwoot` |
| `REDIS_PASSWORD` | misma en `.env` y en `REDIS_URL` |
| `REDIS_URL` | `redis://:PASSWORD@redis:6379` |

Resend: `SMTP_ADDRESS=smtp.resend.com`, `SMTP_PORT=587`, `SMTP_USERNAME=resend`, `SMTP_PASSWORD=re_...`

## Arranque (primera vez, si CI aún no desplegó)

En tools hace falta un `docker login` a ECR. El camino normal es **Run workflow → Deploy Production**, que loguea y hace pull. Manual solo si ya tienes password/sesión:

```bash
export COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
$COMPOSE pull
$COMPOSE run --rm rails bundle exec rails db:chatwoot_prepare
$COMPOSE up -d --no-build
```

## Nginx + SSL

Proxy a `127.0.0.1:3000`. Plantilla: `deployment/nginx_chatwoot.conf`.

```bash
sudo certbot --nginx -d support.lootea.com.mx
```

## SuperAdmin sin Account

```bash
$COMPOSE run --rm rails bundle exec rails runner "
account = Account.create!(name: 'Lootea')
user = User.find_by!(email: 'TU_EMAIL')
AccountUser.create!(account: account, user: user, role: :administrator)
"
```
