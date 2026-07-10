# Documentación Chatwoot Lootea

Fork [lootea/chatwoot](https://github.com/lootea/chatwoot) · Docker en VPS · `support.lootea.com.mx`

## Ramas

| Rama | Uso |
|---|---|
| `develop` | Trabajo diario |
| `main` | Producción (push → deploy automático) |

## Guías

| Doc | Contenido |
|---|---|
| [architecture/overview.md](architecture/overview.md) | Stack y remotes |
| [deploy/initial-setup.md](deploy/initial-setup.md) | Primera instalación |
| [deploy/update-own-changes.md](deploy/update-own-changes.md) | develop → main |
| [deploy/production-workflow.md](deploy/production-workflow.md) | GitHub Actions + secrets |
| [upstream/sync-releases.md](upstream/sync-releases.md) | Releases oficiales |
| [operations/day-to-day.md](operations/day-to-day.md) | Comandos en el VPS |

## Compose (VPS)

```bash
export COMPOSE="docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml"
```
