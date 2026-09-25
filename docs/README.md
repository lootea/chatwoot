# Documentación Chatwoot Lootea

Fork [lootea/chatwoot](https://github.com/lootea/chatwoot) · imagen ECR · pull en VPS tools · `support.lootea.com.mx`

## Ramas

| Rama | Uso |
|---|---|
| `develop` | Trabajo diario y merge de tags upstream |
| `main` | Producción (push → publica imagen → tools pull) |

## Guías

| Doc | Contenido |
|---|---|
| [architecture/overview.md](architecture/overview.md) | Stack, remotes, registry |
| [fork/diff.md](fork/diff.md) | Qué cambia el fork vs upstream y por qué |
| [fork/vs-config.md](fork/vs-config.md) | Cuándo forkear vs configurar (Grafana = no) |
| [deploy/initial-setup.md](deploy/initial-setup.md) | Primera instalación |
| [deploy/update-own-changes.md](deploy/update-own-changes.md) | develop → main |
| [deploy/production-workflow.md](deploy/production-workflow.md) | ECR + Actions + secrets |
| [upstream/sync-releases.md](upstream/sync-releases.md) | Cadencia, checklist, Slack |
| [operations/day-to-day.md](operations/day-to-day.md) | Comandos en tools |

## Compose (tools)

```bash
export COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
```

`CHATWOOT_IMAGE` vive en `.env` (la escribe el deploy de CI). Nunca `compose build` en el servidor.
