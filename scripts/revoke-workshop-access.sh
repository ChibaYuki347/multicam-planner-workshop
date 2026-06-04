#!/usr/bin/env bash
#
# revoke-workshop-access.sh
#
# grant-workshop-access.sh で付与した "Cognitive Services OpenAI User" ロールを
# Azure OpenAI / AIServices アカウントスコープから取り除きます。
# ワークショップ終了後に実行します。
#
# 使い方:
#   RG=rg-sdd-workshop \
#   RESOURCE_NAME=aoai-sdd-workshop \
#   USERS="alice@example.com bob@example.com" \
#   ./revoke-workshop-access.sh

set -euo pipefail

RG="${RG:-rg-sdd-workshop}"
RESOURCE_NAME="${RESOURCE_NAME:-aoai-sdd-workshop}"
ROLE_NAME="${ROLE_NAME:-Cognitive Services OpenAI User}"
USERS="${USERS:-}"
USER_LIST_FILE="${USER_LIST_FILE:-}"

log()  { printf '\n\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\n\033[1;33m[%s] WARN:\033[0m %s\n' "$(date +%H:%M:%S)" "$*" >&2; }
fail() { printf '\n\033[1;31m[%s] ERROR:\033[0m %s\n' "$(date +%H:%M:%S)" "$*" >&2; exit 1; }

command -v az >/dev/null 2>&1 || fail "az CLI が見つかりません。"
az account show >/dev/null 2>&1 || fail "az login 済みではありません。"

if [[ -z "${USERS}" && -z "${USER_LIST_FILE}" ]]; then
  fail "USERS 環境変数または USER_LIST_FILE のどちらかを指定してください。"
fi

ACCOUNT_ID="$(az cognitiveservices account show \
  --name "${RESOURCE_NAME}" --resource-group "${RG}" \
  --query id -o tsv 2>/dev/null)" || fail "アカウント '${RESOURCE_NAME}' が見つかりません。"

USER_LIST=()
if [[ -n "${USERS}" ]]; then
  IFS=$', \n\t' read -r -a USER_LIST <<< "${USERS}"
fi
if [[ -n "${USER_LIST_FILE}" ]]; then
  [[ -f "${USER_LIST_FILE}" ]] || fail "USER_LIST_FILE が見つかりません: ${USER_LIST_FILE}"
  while IFS= read -r line; do
    line="$(echo "${line}" | tr -d '[:space:]')"
    [[ -n "${line}" && "${line}" != \#* ]] && USER_LIST+=("${line}")
  done < "${USER_LIST_FILE}"
fi

[[ "${#USER_LIST[@]}" -gt 0 ]] || fail "ユーザーリストが空です。"

REVOKED=0
NOT_FOUND=0
for upn in "${USER_LIST[@]}"; do
  [[ -z "${upn}" ]] && continue
  log "対象: ${upn}"
  oid="$(az ad user show --id "${upn}" --query id -o tsv 2>/dev/null || true)"
  if [[ -z "${oid}" ]]; then
    warn "  UPN '${upn}' が見つかりませんでした。スキップ。"
    NOT_FOUND=$((NOT_FOUND+1))
    continue
  fi

  if az role assignment delete \
       --assignee "${oid}" \
       --scope "${ACCOUNT_ID}" \
       --role "${ROLE_NAME}" \
       --output none 2>/dev/null; then
    log "  ロールを撤収しました。"
    REVOKED=$((REVOKED+1))
  else
    warn "  撤収対象のロールが見つかりませんでした。"
    NOT_FOUND=$((NOT_FOUND+1))
  fi
done

cat <<EOM

==========================================================
  ロール撤収サマリ
==========================================================
  対象人数:       ${#USER_LIST[@]}
  撤収成功:       ${REVOKED}
  見つからない:   ${NOT_FOUND}
==========================================================

アカウント自体を削除する場合は、撤収不要です:
  RG=${RG} ./teardown-foundry-openai.sh
EOM
