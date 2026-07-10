# Setup inicial

VPS dedicado, Docker, rama **`main`**.

## Clone

```bash
sudo mkdir -p /var/www && cd /var/www
sudo git clone -b main https://github.com/lootea/chatwoot.git chatwoot
cd /var/www/chatwoot
cp .env.example .env && chmod 600 .env
```

## `.env` mínimo

| Variable | Valor |
|---|---|
| `FRONTEND_URL` | `https://support.lootea.com.mx` |
| `FORCE_SSL` | `true` |
| `SECRET_KEY_BASE` | `openssl rand -hex 64` |
| `RAILS_ENV` | `production` |
| `POSTGRES_*` | host `postgres`, user `postgres`, db `chatwoot` |
| `REDIS_PASSWORD` | misma en `.env` y en `REDIS_URL` |
| `REDIS_URL` | `redis://:PASSWORD@redis:6379` |

Resend: `SMTP_ADDRESS=smtp.resend.com`, `SMTP_PORT=587`, `SMTP_USERNAME=resend`, `SMTP_PASSWORD=re_...`

## Arranque

```bash
export COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
$COMPOSE build
$COMPOSE run --rm rails bundle exec rails db:chatwoot_prepare
$COMPOSE up -d
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
