# scripts/

ワークショップ運営用の補助スクリプト置き場です。主に **BYOK バックアップ (Microsoft Foundry / Azure OpenAI) リソースのデプロイと撤収** を扱います。

参加者は基本的にこのフォルダを触る必要はありません。主催者専用です。

## ファイル

| ファイル | 用途 |
|---|---|
| `deploy-foundry-openai.sh` | リソースグループ + AIServices アカウント + モデル deployment を 1 コマンドで作成し、Endpoint / Deployment Name / (取得可なら) API Key を出力 |
| `teardown-foundry-openai.sh` | ワークショップ終了後にリソースグループをまるごと削除 |
| `grant-workshop-access.sh` | Entra ID 認証経路で、参加者 UPN リストに `Cognitive Services OpenAI User` ロールを付与 |
| `revoke-workshop-access.sh` | ワークショップ終了後にロールを撤収 (リソースを残して再利用したい場合) |

## 前提

- macOS / Linux / WSL 上の bash
- `az` CLI v2.60 以上 (v2.86 以上を推奨。`--model-version` 必須化に対応)
- `az login` 済み (適切なサブスクリプションが選択されていること)
- 対象 Azure サブスクリプションで Azure OpenAI / Foundry の利用が承認済み
- ロール付与スクリプトを使う場合: 実行者が対象アカウントの Owner / User Access Administrator 権限を持つこと

## 認証方式の自動判別

`deploy-foundry-openai.sh` は実行時にテナントポリシーを確認し、出力の `Auth Mode:` で次を示します。

- `apikey` — API Key 認証が使える (個人サブ向け)。配布物に API Key を含めます。
- `entra` — API Key 認証がポリシーで禁止されている。`grant-workshop-access.sh` で参加者にロール付与してください。

## 最短手順

### 方式 A (API Key) — 個人サブスクリプション向け

```bash
cd scripts

# 1. デプロイ (出力末尾の Auth Mode が apikey なら OK)
RG=rg-sdd-workshop \
LOCATION=eastus2 \
RESOURCE_NAME=aoai-sdd-workshop \
DEPLOYMENT_NAME=gpt-5-prod \
MODEL_NAME=gpt-5 \
CAPACITY=200 \
./deploy-foundry-openai.sh

# 2. ワークショップ実施 (Endpoint / Deployment Name / API Key を非公開チャネルで配布)

# 3. 撤収
RG=rg-sdd-workshop ./teardown-foundry-openai.sh
```

### 方式 B (Entra ID) — エンタープライズサブスクリプション向け

```bash
cd scripts

# 1. デプロイ (出力末尾の Auth Mode が entra ならこちら)
RG=rg-sdd-workshop \
LOCATION=eastus2 \
RESOURCE_NAME=aoai-sdd-workshop \
DEPLOYMENT_NAME=gpt-5-prod \
MODEL_NAME=gpt-5 \
CAPACITY=200 \
./deploy-foundry-openai.sh

# 2. 参加者 UPN にロール付与
RG=rg-sdd-workshop \
RESOURCE_NAME=aoai-sdd-workshop \
USERS="alice@example.com bob@example.com" \
./grant-workshop-access.sh

# 3. ワークショップ実施 (Endpoint / Deployment Name / テナント情報を配布、API Key は配布しない)

# 4a. リソースごと撤収 (推奨)
RG=rg-sdd-workshop ./teardown-foundry-openai.sh

# 4b. または、ロールだけ撤収してリソース継続利用
RG=rg-sdd-workshop \
RESOURCE_NAME=aoai-sdd-workshop \
USERS="alice@example.com bob@example.com" \
./revoke-workshop-access.sh
```

## モデル切替 (フォールバック)

gpt-5 がそのテナント / リージョンで利用できない場合や、TPM クォータが 0 の場合は、`MODEL_NAME` を変えて再実行してください。

```bash
MODEL_NAME=gpt-5-mini ./deploy-foundry-openai.sh
MODEL_NAME=gpt-4.1    ./deploy-foundry-openai.sh
MODEL_NAME=gpt-4o     ./deploy-foundry-openai.sh
```

> 利用可能モデル一覧:
> `az cognitiveservices model list --location eastus2 -o table | grep -i gpt`
>
> 現在のクォータ:
> `az cognitiveservices usage list --location eastus2 -o table | grep -i gpt`

## コスト目安

- 短時間ワークショップ (3 時間 / 10 人) でも、gpt-5 系フルサイズだと数千円規模になり得ます。
- Budget Alert を必ず設定してください。`az consumption budget create` または Azure Portal から設定可能です。
- 撤収忘れが最大のコストリスクです。**ワークショップ終了直後に必ず teardown** を実行してください。

## セキュリティ

- 生成された `.env.workshop` (リポジトリルート) は `.gitignore` で除外されます。
- API Key / UPN リスト / テナント ID を **公開チャンネル / GitHub / 画面共有 / 録画** に絶対に含めないでください。
- 当日限定の運用とし、終了後はキーをローテーション (deploy したリソースを削除すれば自動的に失効します)。
- Entra ID 方式の場合、ロール撤収忘れに注意 (リソース削除すれば自動撤収)。

詳しい主催者向け運用は `../facilitator/byok-setup.md` を参照してください。
