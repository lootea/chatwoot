#!/usr/bin/env bash
# Compara releases/GHSA de chatwoot/chatwoot vs este fork y avisa a Slack.
set -euo pipefail

UPSTREAM="${UPSTREAM_REPO:-chatwoot/chatwoot}"
STATE_FILE="${STATE_FILE:-/tmp/upstream-watch-state.json}"
WEBHOOK="${SLACK_WEBHOOK_URL:-}"
OUR_VERSION="$(tr -d '[:space:]' < VERSION_CW)"

if [ -z "$WEBHOOK" ]; then
  echo "Missing SLACK_WEBHOOK_URL" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  printf '%s\n' '{"last_release_notified":"","advisories_notified":[]}' > "$STATE_FILE"
fi

post_slack() {
  local text="$1"
  curl -sS -X POST -H 'Content-type: application/json' \
    --data "$(jq -n --arg text "$text" '{text:$text}')" \
    "$WEBHOOK" >/dev/null
}

latest_json="$(gh api "repos/${UPSTREAM}/releases" \
  --jq '[.[] | select(.draft==false and .prerelease==false)][0]')"

if [ -z "$latest_json" ] || [ "$latest_json" = "null" ]; then
  echo "No stable upstream release found"
  exit 1
fi

latest_tag="$(printf '%s' "$latest_json" | jq -r '.tag_name')"
latest_url="$(printf '%s' "$latest_json" | jq -r '.html_url')"
latest_name="$(printf '%s' "$latest_json" | jq -r '.name // .tag_name')"
last_notified="$(jq -r '.last_release_notified // ""' "$STATE_FILE")"
our_tag="v${OUR_VERSION}"

tmp_advisories="$(mktemp)"
gh api "repos/${UPSTREAM}/security-advisories?per_page=50&state=published" > "$tmp_advisories"

notified_ids="$(jq -r '.advisories_notified // [] | .[]' "$STATE_FILE")"
existing_advisory_count="$(jq '.advisories_notified // [] | length' "$STATE_FILE")"
new_ids=()

if [ -z "$last_notified" ] && [ "$existing_advisory_count" = "0" ]; then
  seed_ids="$(jq -c '[.[].ghsa_id]' "$tmp_advisories")"
  behind=""
  if [ "$latest_tag" != "$our_tag" ]; then
    behind=" El fork está atrás: mergear ${latest_tag} esta semana."
  fi
  post_slack ":eyes: Watch de upstream Chatwoot armado. Baseline del fork: *${our_tag}*. Último estable: *${latest_tag}*.${behind}
${latest_url}"
  jq -n \
    --arg release "$latest_tag" \
    --argjson advisories "$seed_ids" \
    '{last_release_notified:$release, advisories_notified:$advisories}' > "${STATE_FILE}.next"
  mv "${STATE_FILE}.next" "$STATE_FILE"
  rm -f "$tmp_advisories"
  echo "Armed watch; seeded $(printf '%s' "$seed_ids" | jq 'length') existing advisories without re-notifying"
  exit 0
fi

if [ "$latest_tag" != "$our_tag" ] && [ "$latest_tag" != "$last_notified" ]; then
  post_slack ":package: *Chatwoot upstream ${latest_name}* (${latest_tag})
Fork Lootea está en *${our_tag}*. Mergear el tag en \`develop\` esta semana (inmediato si es patch de seguridad).
Checklist: \`docs/upstream/sync-releases.md\`
${latest_url}"
  echo "Notified new release ${latest_tag}"
elif [ "$latest_tag" = "$our_tag" ]; then
  echo "Fork is on latest stable ${latest_tag}"
else
  echo "Release ${latest_tag} already notified; still pending merge"
fi

while IFS= read -r row; do
  [ -z "$row" ] && continue
  ghsa="$(printf '%s' "$row" | jq -r '.ghsa_id')"
  severity="$(printf '%s' "$row" | jq -r '.severity // "unknown"')"
  summary="$(printf '%s' "$row" | jq -r '.summary')"
  url="$(printf '%s' "$row" | jq -r '.html_url')"
  if printf '%s\n' "$notified_ids" | grep -qx "$ghsa"; then
    continue
  fi
  post_slack ":rotating_light: *GHSA ${ghsa}* (${severity}) en ${UPSTREAM}
${summary}
Sync *inmediato*. Checklist: \`docs/upstream/sync-releases.md\`
${url}"
  new_ids+=("$ghsa")
  echo "Notified advisory ${ghsa}"
done < <(jq -c '.[]' "$tmp_advisories")

all_ids="$(printf '%s\n' "$notified_ids" "${new_ids[@]:-}" | awk 'NF' | sort -u | jq -R . | jq -s .)"

jq -n \
  --arg release "$latest_tag" \
  --argjson advisories "$all_ids" \
  '{last_release_notified:$release, advisories_notified:$advisories}' > "${STATE_FILE}.next"
mv "${STATE_FILE}.next" "$STATE_FILE"
rm -f "$tmp_advisories"
