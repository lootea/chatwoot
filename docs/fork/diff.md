# Diff auditado: Lootea vs upstream

Inventario de lo que el fork [lootea/chatwoot](https://github.com/lootea/chatwoot) cambia respecto a [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot), y por qué.

**Regla:** cualquier cambio de producto (Ruby, Vue, schema) se documenta aquí **en el mismo PR**. Si no está en esta tabla, no es customización consciente.

## Baseline actual

| Campo | Valor |
|---|---|
| Upstream tracked | tag estable `v4.16.2` (`70e284a044`) |
| Versión declarada | `VERSION_CW` = `4.16.2` |
| Commits Lootea encima del tag | ver `git log --oneline v$(tr -d '[:space:]' < VERSION_CW)..HEAD` |
| Código de aplicación | **sin parches** — branding y SMTP van por `.env` / Super Admin |
| Cómo regenerar | `.github/scripts/fork_diff.sh` |

## Archivos propios (no existen en upstream)

| Path | Por qué existe |
|---|---|
| `docker-compose.lootea.yml` | Overlay de producción: imagen ECR `lootea/chatwoot`, no `chatwoot/chatwoot:latest` |
| `.github/workflows/deploy-production.yml` | Publish ECR + pull en el VPS tools |
| `.github/workflows/publish-ecr.yml` | Receta de imagen (mismo registry que el backend) |
| `.github/workflows/upstream-watch.yml` | Aviso Slack cuando upstream publica release o GHSA |
| `.github/scripts/deploy_chatwoot.sh` | Deploy en tools: pull, migrate, smoke, rollback de imagen |
| `.github/scripts/upstream_watch.sh` | Compara release/GHSA de `chatwoot/chatwoot` vs este fork |
| `.github/scripts/fork_diff.sh` | Regenera el inventario `git` vs el tag de `VERSION_CW` |
| `.gitattributes` | LF en scripts del fork (Actions + tools son Linux) |
| `docs/**` | Proceso del fork, deploy y operación Lootea |

## Archivos upstream modificados

Ninguno. No tocamos Ruby, Vue, Dockerfile, ni compose oficial. Así el merge de un tag estable no pelea con parches de producto.

## Qué no es un fork (y no va aquí)

| Cosa | Dónde vive |
|---|---|
| `FRONTEND_URL`, SMTP, `SECRET_KEY_BASE` | `.env` en el VPS tools (nunca en git) |
| Account / Super Admin / logo | runtime Chatwoot |
| Nginx + TLS `support.lootea.com.mx` | host tools |
| Postgres / Redis de Chatwoot | `docker-compose.production.yaml` (upstream) + password en `.env` |

## Historial de commits Lootea (referencia)

Los SHA cambian si reescribimos historia; la fuente de verdad es el comando de arriba.

| Tema | Commits originales |
|---|---|
| Overlay compose | `chore(deploy): add lootea docker compose override` |
| Deploy Actions | `chore(deploy): add production deploy workflow` |
| Guías | `docs: add deployment and operations guides` |
| Sync | `Merge tag 'vX.Y.Z' into develop` (uno por release) |

## Si hay que tocar código fuente

1. Confirmar que no existe vía config/plugin/API — ver [vs-config.md](vs-config.md).
2. Parche mínimo en un commit convencional (`feat(lootea): …` / `fix(lootea): …`).
3. Añadir fila en **Archivos upstream modificados** con el motivo.
4. El siguiente sync usará merge del tag (no rebase de `develop`/`main`).
