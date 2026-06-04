#!/usr/bin/env bash
#
# grant-workshop-access.sh
#
# Entra ID 認証経路で BYOK を使う場合、参加者に "Cognitive Services OpenAI User"
# ロールを Azure OpenAI / AIServices アカウントスコープで付与します。
#
# 使い方:
#   RG=rg-sdd-workshop \
#   RESOURCE_NAME=aoai-sdd-workshop \
#   USERS="alice@example.com bob@example.com" \
#   ./grant-workshop-access.sh
#
#   または USERS の代わりに USER_LIST_FILE=users.txt を指定 (1 行 1 UPN)
#
# 前提:
#   - 参加者は同じ Entra ID テナント内のユーザーであること (ゲスト招待済みでも可)
#   - 実行者は対象アカウントの Owner / User Access Administrator 権限が必要

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

log "Resource: ${ACCOUNT_ID}"
log "Role:     ${ROLE_NAME}"

USER_LIST=()
if [[ -n "${USERS}" ]]; then
  # スペース / カンマ / 改行を区切り文字として扱う
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

GRANTED=0
SKIPPED=0
FAILED=0
for upn in "${USER_LIST[@]}"; do
  [[ -z "${upn}" ]] && continue
  log "対象: ${upn}"
  oid="$(az ad user show --id "${upn}" --query id -o tsv 2>/dev/null || true)"
  if [[ -z "${oid}" ]]; then
    warn "  UPN '${upn}' が見つかりませんでした。スキップします。"
    FAILED=$((FAILED+1))
    continue
  fi

  if az role assignment list \
       --assignee "${oid}" \
       --scope "${ACCOUNT_ID}" \
       --role "${ROLE_NAME}" \
       --query "[0].id" -o tsv 2>/dev/null | grep -q .; then
    log "  既に '${ROLE_NAME}' が割り当て済み。スキップ。"
    SKIPPED=$((SKIPPED+1))
    continue
  fi

  if az role assignment create \
       --assignee-object-id "${oid}" \
       --assignee-principal-type User \
       --role "${ROLE_NAME}" \
       --scope "${ACCOUNT_ID}" \
       --output none 2>&1 | head -3; then
    log "  ロールを付与しました。"
    GRANTED=$((GRANTED+1))
  else
    warn "  付与に失敗しました。"
    FAILED=$((FAILED+1))
  fi
done

cat <<EOM

==========================================================
  ロール付与サマリ
==========================================================
  対象人数:   ${#USER_LIST[@]}
  新規付与:   ${GRANTED}
  既に付与済: ${SKIPPED}
  失敗:       ${FAILED}
==========================================================

参加者には次の 3 点を配布してください:

  Endpoint:        $(az cognitiveservices account show --name "${RESOURCE_NAME}" --resource-group "${RG}" --query properties.endpoint -o tsv)
  Deployment Name: (デプロイ時に指定した DEPLOYMENT_NAME, 例: gpt-4-1-prod)
  Auth Mode:       Microsoft Entra ID (テナント: $(az account show --query tenantId -o tsv))

ロール伝搬には数分かかることがあります。参加者にはサインアウト / サインインを案内すると確実です。
EOM
