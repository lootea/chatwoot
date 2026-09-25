# Sincronizar con upstream

```text
aviso Slack (release o GHSA) → merge tag en develop → prueba → merge a main → CI publica imagen → tools pull
```

## Cadencia

| Evento | Cuándo | Quién |
|---|---|---|
| Release estable `vX.Y.Z` (no pre-release) | En la **misma semana** del aviso Slack | quien opere el fork |
| Patch / hotfix de seguridad | **Inmediato** (mismo día hábil) | quien opere el fork |
| GHSA / CVE publicado en `chatwoot/chatwoot` | **Inmediato**, aunque no haya tag todavía | quien opere el fork |
| `upstream/develop` o nightlies | No se mergea | — |

El watcher (`.github/workflows/upstream-watch.yml`) corre cada 4 h y avisa a Slack **una vez** por release/GHSA nuevo. No mergea solo.

Usa **tags anotados** (`vX.Y.Z`). Nunca `git merge upstream/develop` a ciegas.

**Merge, no rebase** de `develop` / `main`. El fork solo añade archivos propios; rebase reescribe historia y pelea con deploys ya hechos. Las topic branches sí pueden rebasearse sobre `develop`.

## Una vez por máquina

```bash
git remote add upstream https://github.com/chatwoot/chatwoot.git
git fetch upstream --tags
```

## Checklist de merge

Copiar a la PR o al mensaje de merge.

### 1. Antes

- [ ] Leer el [changelog](https://github.com/chatwoot/chatwoot/releases) del tag (breaking, `.env` nuevas, migraciones).
- [ ] `git fetch upstream --tags && git fetch origin`
- [ ] Confirmar que `develop` está limpio: `git status`
- [ ] Si es GHSA sin tag: esperar el release oficial **o** cherry-pickear el commit citado en el advisory (documentar el SHA en [../fork/diff.md](../fork/diff.md)).

### 2. Merge del tag en develop

```bash
git checkout develop && git pull --ff-only origin develop
git merge vX.Y.Z
# resolver conflictos. Casi siempre solo archivos Lootea vs deletes/renames de CI upstream.
git push origin develop
```

- [ ] Conflictos resueltos **sin** reintroducir workflows upstream que hayamos dejado deshabilitados en la UI de Actions.
- [ ] `VERSION_CW` coincide con el tag mergeado.
- [ ] [../fork/diff.md](../fork/diff.md) sigue siendo cierto (`bash .github/scripts/fork_diff.sh`). Si el release tocó un archivo que parcheamos, actualizar la tabla.

### 3. Prueba post-sync (antes de main)

Mínimo, en local o en una máquina con Docker:

- [ ] `docker compose -f docker-compose.production.yaml -f docker-compose.lootea.yml config` (interpola `CHATWOOT_IMAGE`; vale un URI dummy).
- [ ] App levanta: login Super Admin, una conversación de prueba, widget si aplica.
- [ ] Revisar migraciones del tag (`db/migrate` nuevas) — ¿son reversibles? ¿tocan tablas grandes?
- [ ] Variables nuevas del release añadidas al `.env` de tools (no commitear).

No hace falta la suite completa de upstream. Si el merge fue limpio y no hay parches de producto, el riesgo es schema + env.

### 4. Producción

```bash
git checkout main && git pull --ff-only origin main
git merge develop
git push origin main
```

- [ ] Actions: **Publish ECR image** verde → **Deploy Production** verde.
- [ ] Tools hizo **pull**, no `build` (`docker compose … pull` en el log SSH).
- [ ] Smoke `/api` y `https://support.lootea.com.mx`.
- [ ] Si el job avisa rollback: la imagen volvió atrás; **las migraciones no**. Ver [../deploy/production-workflow.md](../deploy/production-workflow.md).

## Aviso Slack

Secret del repo: `SLACK_WEBHOOK_URL` (incoming webhook al canal de infra / `#alertas-tools`).

El job compara el último release estable y los GHSA publicados de `chatwoot/chatwoot` contra `VERSION_CW` y el estado cacheado. Se repeite el aviso de release mientras el fork no incorpore ese tag.

## Workflows upstream en este fork

No editar los YAML de Chatwoot Inc. (conflictos en cada sync). Tras el primer setup, en **Actions → … → Disable workflow** dejar apagados:

`Publish Chatwoot CE/EE docker images`, `Publish Codespace Base Image`, `Sync GHSA advisories to Linear`, `Nightly installer`, `Deploy Check` (Heroku), `stale`, `lock`, `auto-assign`, specs/lint de upstream si no vamos a pagar esos runners.

GitHub **recuerda** el disable aunque el archivo cambie en el merge. El checklist de arriba solo pide verificar que no se re-habilitaron.
