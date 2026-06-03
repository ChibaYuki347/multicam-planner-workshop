# scripts/

ワークショップ運営用の補助スクリプト置き場です。主に **BYOK バックアップ (Microsoft Foundry / Azure OpenAI) リソースのデプロイと撤収** を扱います。

参加者は基本的にこのフォルダを触る必要はありません。主催者専用です。

## ファイル

| ファイル | 用途 |
|---|---|
| `deploy-foundry-openai.sh` | リソースグループ + AIServices アカウント + モデル deployment を 1 コマンドで作成し、Endpoint / API Key / Deployment Name を出力 |
| `teardown-foundry-openai.sh` | ワークショップ終了後にリソースグループをまるごと削除 |

## 前提

- macOS / Linux / WSL 上の bash
- `az` CLI v2.60 以上
- `az login` 済み (適切なサブスクリプションが選択されていること)
- 対象 Azure サブスクリプションで Azure OpenAI / Foundry の利用が承認済み

## 最短手順

```bash
cd scripts

# 1. デプロイ
RG=rg-sdd-workshop \
LOCATION=eastus2 \
RESOURCE_NAME=aoai-sdd-workshop \
DEPLOYMENT_NAME=gpt-5-prod \
MODEL_NAME=gpt-5 \
CAPACITY=200 \
./deploy-foundry-openai.sh

# 2. ワークショップ実施 (Endpoint / API Key / Deployment Name を参加者に配布)

# 3. 撤収
RG=rg-sdd-workshop ./teardown-foundry-openai.sh
```

## モデル切替 (フォールバック)

gpt-5 がそのテナント / リージョンで利用できない場合は、`MODEL_NAME` を変えて再実行してください。

```bash
MODEL_NAME=gpt-5-mini ./deploy-foundry-openai.sh
MODEL_NAME=gpt-4.1    ./deploy-foundry-openai.sh
MODEL_NAME=gpt-4o     ./deploy-foundry-openai.sh
```

> 利用可能モデルの確認:
> `az cognitiveservices model list --location eastus2 -o table | grep -i gpt`

## コスト目安

- 短時間ワークショップ (3 時間 / 10 人) でも、gpt-5 系フルサイズだと数千円規模になり得ます。
- Budget Alert を必ず設定してください。`az consumption budget create` または Azure Portal から設定可能です。
- 撤収忘れが最大のコストリスクです。**ワークショップ終了直後に必ず teardown** を実行してください。

## セキュリティ

- 生成された `.env.workshop` (リポジトリルート) は `.gitignore` で除外されます。
- API Key を **公開チャンネル / GitHub / 画面共有 / 録画** に絶対に含めないでください。
- 当日限定の運用とし、終了後はキーをローテーション (deploy したリソースを削除すれば自動的に失効します)。

詳しい主催者向け運用は `../facilitator/byok-setup.md` を参照してください。
