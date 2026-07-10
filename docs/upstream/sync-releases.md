# Sincronizar releases oficiales

```text
upstream tag → develop → main → Actions
```

## Upstream (una vez)

```bash
git remote add upstream https://github.com/chatwoot/chatwoot.git
git fetch upstream --tags
```

## Merge en develop

```bash
git checkout develop && git pull origin develop
git merge vX.Y.Z
git push origin develop
```

Usa **tags** (`vX.Y.Z`), no `upstream/develop` a ciegas.

## A producción

```bash
git checkout main && git pull origin main
git merge develop
git push origin main
```

Deploy automático. Revisa `.env` si el release pide variables nuevas.
