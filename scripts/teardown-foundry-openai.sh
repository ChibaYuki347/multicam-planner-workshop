#!/usr/bin/env bash
#
# teardown-foundry-openai.sh
#
# deploy-foundry-openai.sh で作成したリソースグループをまるごと削除します。
# 確認プロンプトを出してから実行します。--yes を渡すと非対話で削除します。
#
# 使い方:
#   RG=rg-sdd-workshop ./teardown-foundry-openai.sh
#   RG=rg-sdd-workshop ./teardown-foundry-openai.sh --yes
#   RG=rg-sdd-workshop ./teardown-foundry-openai.sh --dry-run

set -euo pipefail

RG="${RG:-rg-sdd-workshop}"
NON_INTERACTIVE=false
DRY_RUN=false

for arg in "$@"; do
  case "${arg}" in
    --yes|-y) NON_INTERACTIVE=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "Unknown argument: ${arg}" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env.workshop"

log()  { printf '\n\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
fail() { printf '\n\033[1;31m[%s] ERROR:\033[0m %s\n' "$(date +%H:%M:%S)" "$*" >&2; exit 1; }

command -v az >/dev/null 2>&1 || fail "az CLI が見つかりません。"
az account show >/dev/null 2>&1 || fail "az login 済みではありません。"

if ! az group show --name "${RG}" >/dev/null 2>&1; then
  log "Resource Group '${RG}' は存在しません。何もしません。"
  exit 0
fi

SUBSCRIPTION_NAME="$(az account show --query name -o tsv)"

cat <<EOM

==========================================================
  撤収対象
==========================================================
  Subscription: ${SUBSCRIPTION_NAME}
  Resource Group: ${RG}
==========================================================
EOM

if [[ "${DRY_RUN}" == "true" ]]; then
  log "[dry-run] az group delete --name '${RG}' --yes --no-wait を実行する予定 (実行しません)"
  exit 0
fi

if [[ "${NON_INTERACTIVE}" != "true" ]]; then
  printf "上記リソースグループを削除します。よろしければ 'delete' と入力してください: "
  read -r CONFIRM
  if [[ "${CONFIRM}" != "delete" ]]; then
    log "中止しました。"
    exit 0
  fi
fi

log "リソースグループ '${RG}' を削除します (バックグラウンド)..."
az group delete --name "${RG}" --yes --no-wait

if [[ -f "${ENV_FILE}" ]]; then
  log "${ENV_FILE} を削除します。"
  rm -f "${ENV_FILE}"
fi

log "削除リクエストを送信しました。完了まで数分かかります。"
log "完了確認: az group show --name '${RG}'  →  ResourceGroupNotFound が返れば完了です。"
