#!/usr/bin/env bash
# Inventario del fork vs el tag declarado en VERSION_CW.
set -euo pipefail

export GIT_PAGER=cat
root="$(git rev-parse --show-toplevel)"
cd "$root"

version="$(tr -d '[:space:]' < VERSION_CW)"
tag="v${version}"

if ! git rev-parse "$tag" >/dev/null 2>&1; then
  echo "Tag ${tag} no existe localmente. git fetch upstream --tags" >&2
  exit 1
fi

echo "Baseline: ${tag} ($(git rev-parse --short "${tag}^{commit}"))"
echo "HEAD:     $(git rev-parse --short HEAD) ($(git rev-parse --abbrev-ref HEAD))"
echo
echo "== Commits Lootea (no están en ${tag}) =="
git --no-pager log --oneline "${tag}..HEAD"
echo
echo "== Paths tocados en commits Lootea =="
git --no-pager log --name-status --pretty=format: "${tag}..HEAD" | awk 'NF && !seen[$0]++'
echo
echo "Si aparece un path de app/ enterprise/ o docker/Dockerfile, actualiza docs/fork/diff.md"
