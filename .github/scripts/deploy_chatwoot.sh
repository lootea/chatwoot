#!/usr/bin/env bash
# Corre en el VPS tools vía SSH. Pull de ECR — nunca build de la app.
set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/chatwoot}"
cd "$APP_DIR"

COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
SMOKE_URL="http://127.0.0.1:3000/api"

: "${CHATWOOT_IMAGE:?CHATWOOT_IMAGE is required}"
: "${ECR_PASSWORD:?ECR_PASSWORD is required}"
: "${ECR_REGISTRY:?ECR_REGISTRY is required}"

case "$CHATWOOT_IMAGE" in
  *.dkr.ecr.*.amazonaws.com/*) ;;
  *)
    echo "[ERROR] CHATWOOT_IMAGE no es un URI de ECR: ${CHATWOOT_IMAGE}"
    exit 1
    ;;
esac

upsert_env() {
  local key="$1" val="$2" file=".env"
  if [ ! -f "$file" ]; then
    echo "[ERROR] Falta ${file} en ${APP_DIR}"
    exit 1
  fi
  if grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$file"
  else
    printf '\n%s=%s\n' "$key" "$val" >> "$file"
  fi
}

running_image() {
  local id
  id="$($COMPOSE ps -q rails 2>/dev/null | head -n1 || true)"
  if [ -n "$id" ]; then
    docker inspect -f '{{.Config.Image}}' "$id" 2>/dev/null || true
  fi
}

smoke_check() {
  local i
  for i in $(seq 1 45); do
    if curl -sf "$SMOKE_URL" >/dev/null; then
      echo "Smoke check OK (attempt $i)"
      return 0
    fi
    sleep 2
  done
  echo "Smoke check FAILED after retries"
  return 1
}

PREVIOUS=""
if [ -f .chatwoot-image ]; then
  PREVIOUS="$(tr -d '[:space:]' < .chatwoot-image)"
fi
if [ -z "$PREVIOUS" ]; then
  PREVIOUS="$(running_image)"
fi

echo "==> Login ECR ${ECR_REGISTRY}"
printf '%s' "$ECR_PASSWORD" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "==> Fetching main"
git fetch origin main
git checkout main
git pull --ff-only origin main

echo "==> Target image ${CHATWOOT_IMAGE}"
upsert_env CHATWOOT_IMAGE "$CHATWOOT_IMAGE"
export CHATWOOT_IMAGE

echo "==> Pull (no build)"
$COMPOSE pull rails sidekiq

echo "==> Preparing database"
$COMPOSE run --rm rails bundle exec rails db:chatwoot_prepare

echo "==> Starting stack"
$COMPOSE up -d --no-build --remove-orphans

if smoke_check; then
  printf '%s\n' "$CHATWOOT_IMAGE" > .chatwoot-image
  echo "==> Deploy successful"
  git rev-parse --short HEAD
  $COMPOSE ps
  exit 0
fi

echo "==> New deploy failed smoke check"

if [ -z "$PREVIOUS" ] || [ "$PREVIOUS" = "$CHATWOOT_IMAGE" ]; then
  echo "No previous image available to roll back to"
  exit 1
fi

echo "==> Rolling back to ${PREVIOUS}"
CHATWOOT_IMAGE="$PREVIOUS"
export CHATWOOT_IMAGE
upsert_env CHATWOOT_IMAGE "$CHATWOOT_IMAGE"
$COMPOSE pull rails sidekiq || true
$COMPOSE up -d --no-build

if smoke_check; then
  echo "::warning::Deploy of the new revision failed the smoke check. Production was rolled back to the previous image and is healthy again. Check migrations manually if db:chatwoot_prepare already ran."
  echo "ROLLBACK_OCCURRED=1"
  git rev-parse --short HEAD
  $COMPOSE ps
  exit 0
fi

echo "==> Rollback also failed smoke check"
exit 1
