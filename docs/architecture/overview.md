# Arquitectura

## Stack

- VPS **tools** (Hostinger KVM): Chatwoot + Grafana/Prometheus central
- `docker-compose.production.yaml` + `docker-compose.lootea.yml` → pull de `CHATWOOT_IMAGE` (ECR `lootea/chatwoot`)
- `.env` solo en el VPS (nunca en git)
- Nginx → `127.0.0.1:3000` (`support.lootea.com.mx`)
- Ruta VPS: `/var/www/chatwoot`, rama `main`

## Ramas e imagen

```text
upstream tag → develop → main → Actions (ECR <sha> + production)
                              → tools: pull, no build
```

## Remotes

| Remote | Repo |
|---|---|
| `origin` | lootea/chatwoot |
| `upstream` | chatwoot/chatwoot (solo fetch/merge de tags) |

## Registry

Mismo ECR e identidad OIDC que `lootea-backend`. Receta: `.github/workflows/publish-ecr.yml`.  
Grafana en el mismo host **no** usa este registry: imagen oficial + provisioning (ver [../fork/vs-config.md](../fork/vs-config.md)).
