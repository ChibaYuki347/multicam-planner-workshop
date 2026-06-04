#!/usr/bin/env bash
#
# deploy-foundry-openai.sh
#
# Microsoft Foundry (Azure OpenAI / Azure AI Services) のリソースを 1 コマンドで作成し、
# ワークショップ用にモデルを deploy して、参加者へ配布する Endpoint / API Key / Deployment Name を出力します。
#
# 必要なもの:
#   - az CLI (v2.60 以上推奨)
#   - az login 済み (適切なサブスクリプションが選ばれていること)
#
# 既定モデル: gpt-5 (full size)
#   テナントで gpt-5 が deploy 不可な場合は、環境変数で MODEL_NAME=gpt-5-mini もしくは
#   MODEL_NAME=gpt-4.1 / MODEL_NAME=gpt-4o などにフォールバックしてください。
#
# 使い方:
#   RG=rg-sdd-workshop \
#   LOCATION=eastus2 \
#   RESOURCE_NAME=aoai-sdd-workshop \
#   DEPLOYMENT_NAME=gpt-5-prod \
#   MODEL_NAME=gpt-5 \
#   CAPACITY=200 \
#   ./deploy-foundry-openai.sh
#
# 出力:
#   - 標準出力に Endpoint / API Key / Deployment Name
#   - リポジトリルートに .env.workshop (gitignore 済) を生成

set -euo pipefail

RG="${RG:-rg-sdd-workshop}"
LOCATION="${LOCATION:-eastus2}"
RESOURCE_NAME="${RESOURCE_NAME:-aoai-sdd-workshop}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-gpt-5-prod}"
MODEL_NAME="${MODEL_NAME:-gpt-5}"
MODEL_VERSION="${MODEL_VERSION:-}"
SKU="${SKU:-GlobalStandard}"
CAPACITY="${CAPACITY:-200}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env.workshop"

log()  { printf '\n\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\n\033[1;33m[%s] WARN:\033[0m %s\n' "$(date +%H:%M:%S)" "$*" >&2; }
fail() { printf '\n\033[1;31m[%s] ERROR:\033[0m %s\n' "$(date +%H:%M:%S)" "$*" >&2; exit 1; }

# -------- 前提チェック --------

command -v az >/dev/null 2>&1 || fail "az CLI が見つかりません。https://learn.microsoft.com/cli/azure/install-azure-cli を参照してください。"

if ! az account show >/dev/null 2>&1; then
  fail "az login 済みではありません。'az login' を実行してから再度試してください。"
fi

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
SUBSCRIPTION_NAME="$(az account show --query name -o tsv)"

log "Subscription: ${SUBSCRIPTION_NAME} (${SUBSCRIPTION_ID})"
log "Region:       ${LOCATION}"
log "Model:        ${MODEL_NAME} (deployment: ${DEPLOYMENT_NAME}, sku: ${SKU}, capacity: ${CAPACITY}k TPM)"

# -------- モデル可用性チェック (best-effort) --------

log "リージョン ${LOCATION} で ${MODEL_NAME} の可用性を確認します..."
if ! az cognitiveservices model list --location "${LOCATION}" \
      --query "[?model.name=='${MODEL_NAME}'].model.name" -o tsv 2>/dev/null \
      | grep -q "${MODEL_NAME}"; then
  warn "${MODEL_NAME} が ${LOCATION} で見つかりませんでした。テナントで該当モデルの利用が承認されていない可能性があります。"
  warn "別モデルへのフォールバック例: MODEL_NAME=gpt-5-mini, MODEL_NAME=gpt-4.1, MODEL_NAME=gpt-4o"
  warn "そのまま続行しますが、deployment 作成で失敗するかもしれません。"
fi

# -------- リソースグループ作成 --------

log "Resource Group '${RG}' を作成 (存在すればスキップ)"
az group create --name "${RG}" --location "${LOCATION}" --output none

# -------- AIServices アカウント作成 (Foundry 互換) --------

log "AIServices アカウント '${RESOURCE_NAME}' を作成 (存在すればスキップ)"
if az cognitiveservices account show --name "${RESOURCE_NAME}" --resource-group "${RG}" >/dev/null 2>&1; then
  warn "アカウントが既に存在します。既存リソースを再利用します。"
else
  az cognitiveservices account create \
    --name "${RESOURCE_NAME}" \
    --resource-group "${RG}" \
    --location "${LOCATION}" \
    --kind AIServices \
    --sku S0 \
    --custom-domain "${RESOURCE_NAME}" \
    --yes \
    --output none
fi

# BYOK は API キー認証または Entra ID 認証のどちらかを使用する。
# 一部のエンタープライズテナントでは disableLocalAuth=true が Azure Policy で
# 強制されているため、ここでの try-update は best-effort で行い、失敗しても続行する。
log "API キー認証の有効化を試行 (disableLocalAuth=false)"
if ! az resource update \
       --resource-type Microsoft.CognitiveServices/accounts \
       --resource-group "${RG}" \
       --name "${RESOURCE_NAME}" \
       --set properties.disableLocalAuth=false \
       --output none 2>/dev/null; then
  warn "disableLocalAuth の変更がポリシーで拒否された可能性があります。Entra ID 認証経路を利用してください。"
fi

LOCAL_AUTH_DISABLED="$(az cognitiveservices account show \
  --name "${RESOURCE_NAME}" --resource-group "${RG}" \
  --query "properties.disableLocalAuth" -o tsv 2>/dev/null || echo "true")"

# -------- モデル deployment --------

DEPLOYMENT_ARGS=(
  --name "${RESOURCE_NAME}"
  --resource-group "${RG}"
  --deployment-name "${DEPLOYMENT_NAME}"
  --model-name "${MODEL_NAME}"
  --model-format OpenAI
  --sku-name "${SKU}"
  --sku-capacity "${CAPACITY}"
)
if [[ -z "${MODEL_VERSION}" ]]; then
  log "MODEL_VERSION 未指定。${LOCATION} で利用可能な最新版を自動取得します..."
  MODEL_VERSION="$(az cognitiveservices model list --location "${LOCATION}" \
    --query "[?model.name=='${MODEL_NAME}'] | sort_by(@, &model.version) | [-1].model.version" \
    -o tsv 2>/dev/null || true)"
  if [[ -z "${MODEL_VERSION}" ]]; then
    fail "${MODEL_NAME} のバージョンを自動取得できませんでした。MODEL_VERSION 環境変数で明示してください。"
  fi
  log "自動選択: MODEL_VERSION=${MODEL_VERSION}"
fi
DEPLOYMENT_ARGS+=(--model-version "${MODEL_VERSION}")

log "Deployment '${DEPLOYMENT_NAME}' を作成 / 更新"
az cognitiveservices account deployment create "${DEPLOYMENT_ARGS[@]}" --output none

# -------- 接続情報の取り出し --------

log "接続情報を取得"
ENDPOINT="$(az cognitiveservices account show \
  --name "${RESOURCE_NAME}" \
  --resource-group "${RG}" \
  --query properties.endpoint -o tsv)"
ACCOUNT_ID="$(az cognitiveservices account show \
  --name "${RESOURCE_NAME}" \
  --resource-group "${RG}" \
  --query id -o tsv)"

API_KEY=""
if [[ "${LOCAL_AUTH_DISABLED}" == "false" ]]; then
  API_KEY="$(az cognitiveservices account keys list \
    --name "${RESOURCE_NAME}" \
    --resource-group "${RG}" \
    --query key1 -o tsv 2>/dev/null || echo "")"
fi

if [[ -z "${API_KEY}" ]]; then
  AUTH_MODE="entra"
else
  AUTH_MODE="apikey"
fi

# -------- 出力 --------

cat <<EOM

==========================================================
  SDD ワークショップ用 BYOK 接続情報
==========================================================
  Endpoint:        ${ENDPOINT}
  Deployment Name: ${DEPLOYMENT_NAME}
  Model:           ${MODEL_NAME} (${MODEL_VERSION})
  Region:          ${LOCATION}
  Capacity:        ${CAPACITY}k TPM (${SKU})
  Auth Mode:       ${AUTH_MODE}
EOM

if [[ "${AUTH_MODE}" == "apikey" ]]; then
cat <<EOM
  API Key:         ${API_KEY}
==========================================================

【参加者へ配布】Endpoint / Deployment Name / API Key を Teams プライベートチャットなど
非公開チャネルで配布してください。公開チャネル / GitHub / 画面共有禁止です。
EOM
else
cat <<EOM
  API Key:         (取得不可: テナントポリシーで API キー認証が無効化されています)
==========================================================

【Entra ID 認証モード】API キーが使えないため、参加者にロールを付与する必要があります。

参加者の UPN リストを用意して、次のコマンドでロールを一括付与してください。

  RG=${RG} RESOURCE_NAME=${RESOURCE_NAME} \\
  USERS="user1@example.com user2@example.com" \\
  ./grant-workshop-access.sh

参加者には次の 3 点を配布してください (API Key 不要):

  Endpoint:        ${ENDPOINT}
  Deployment Name: ${DEPLOYMENT_NAME}
  Auth Mode:       Microsoft Entra ID (テナントにサインインしてください)

ワークショップ後はロール撤収を忘れずに:
  RG=${RG} RESOURCE_NAME=${RESOURCE_NAME} \\
  USERS="user1@example.com user2@example.com" \\
  ./revoke-workshop-access.sh
EOM
fi

cat > "${ENV_FILE}" <<EOF
# Auto-generated by scripts/deploy-foundry-openai.sh
# 公開禁止。.gitignore で除外されています。
AZURE_OPENAI_ENDPOINT=${ENDPOINT}
AZURE_OPENAI_DEPLOYMENT=${DEPLOYMENT_NAME}
AZURE_OPENAI_MODEL=${MODEL_NAME}
AZURE_OPENAI_MODEL_VERSION=${MODEL_VERSION}
AZURE_OPENAI_REGION=${LOCATION}
AZURE_OPENAI_ACCOUNT_ID=${ACCOUNT_ID}
AZURE_OPENAI_AUTH_MODE=${AUTH_MODE}
EOF

if [[ "${AUTH_MODE}" == "apikey" ]]; then
  echo "AZURE_OPENAI_API_KEY=${API_KEY}" >> "${ENV_FILE}"
fi

chmod 600 "${ENV_FILE}"
log "接続情報を ${ENV_FILE} に書き出しました (パーミッション 600)。"
log "撤収するときは: RG=${RG} ./teardown-foundry-openai.sh"
