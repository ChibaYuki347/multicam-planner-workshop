# BYOK バックアップ運用ガイド (主催者専用)

GitHub Copilot のクォータがワークショップ中に枯渇するリスクへの備えとして、Microsoft Foundry (Azure OpenAI) を BYOK で参加者に開放する運用手順です。参加者向けの切替手順は `../docs/05-backup-byok.md` を参照してください。

## 1. 事前準備チェックリスト

- [ ] Azure サブスクリプションがあり、Owner または Contributor 権限を持っている
- [ ] サブスクリプションで Azure OpenAI / Foundry の利用が承認済み (新規テナントは申請が必要なことがある)
- [ ] `az` CLI がインストール済み (v2.60 以上推奨)
- [ ] `az login` 済みで、`az account show` で正しいサブスクリプションが選ばれている
- [ ] リージョン `eastus2` で対象モデル (例: `gpt-5`) の deploy 可用性を確認した
  - 確認コマンド: `az cognitiveservices model list --location eastus2 --query "[?contains(model.name, 'gpt-5')]" -o table`
- [ ] Budget Alert を設定する予定があるか決めた (推奨)
- [ ] キー配布チャネルを決めた (Teams プライベートチャット / 1Password 共有 / 紙配布 など、公開チャンネル禁止)

## 2. 1 コマンドでデプロイ

リポジトリ同梱の `scripts/deploy-foundry-openai.sh` を使うと、リソースグループ作成 → AIServices アカウント作成 → モデル deploy → キー出力までを 1 コマンドで実行できます。

```bash
cd scripts
RG=rg-sdd-workshop \
LOCATION=eastus2 \
RESOURCE_NAME=aoai-sdd-workshop \
DEPLOYMENT_NAME=gpt-5-prod \
MODEL_NAME=gpt-5 \
CAPACITY=200 \
./deploy-foundry-openai.sh
```

実行後、`.env.workshop` ファイル (gitignore 済) と標準出力に、参加者へ配布する 3 点 (Endpoint / API Key / Deployment Name) が出力されます。

### よくあるパラメータ

| 環境変数 | 既定値 | 説明 |
|---|---|---|
| `RG` | `rg-sdd-workshop` | リソースグループ名 |
| `LOCATION` | `eastus2` | Azure リージョン |
| `RESOURCE_NAME` | `aoai-sdd-workshop` | AIServices アカウント名。グローバルに一意 |
| `DEPLOYMENT_NAME` | `gpt-5-prod` | VS Code BYOK で指定する deployment 名 |
| `MODEL_NAME` | `gpt-5` | Azure モデル ID。gpt-5 系が不可なら `gpt-5-mini` / `gpt-4.1` / `gpt-4o` |
| `MODEL_VERSION` | (空) | 省略時は最新版を自動採用 |
| `SKU` | `GlobalStandard` | deployment SKU |
| `CAPACITY` | `200` | TPM (千トークン/分)。参加人数に応じて調整 |

### TPM の目安

| 参加人数 | 想定 CAPACITY (千 TPM) | 補足 |
|---:|---:|---|
| 〜 5 名 | 100 | リハーサルや小規模 |
| 6 〜 10 名 | 200 | 標準 |
| 11 〜 20 名 | 400 | 余裕を持たせる |
| 21 名〜 | 800 + 別リソース併用 | 複数リソースに分散する |

足りないと感じたら、同じスクリプトで `RESOURCE_NAME` を変えてもう一つデプロイし、参加者を半分ずつに割り振る運用が手堅いです。

## 3. キーの安全な配布

- **NG**: 公開チャンネル / 共有ドキュメント / GitHub Issue / PR / コミット
- **OK**: Teams プライベートチャット (1:1 or 主催者→各人)、1Password 等の共有金庫、紙配布、当日限定の貼り出し

配布物テンプレート:

```
件名: 【SDD ワークショップ】BYOK 切替時の接続情報
本文:
  Endpoint:        https://aoai-sdd-workshop.openai.azure.com/
  API Key:         <ここに記載>
  Deployment Name: gpt-5-prod
  有効期限:        本日のワークショップ終了まで
  使い方:          docs/05-backup-byok.md を参照
```

## 4. 当日の運用

### 4.1 オープニング (0:00 - 0:10)

参加者に次を 1 分でアナウンスします。

> Copilot が応答しなくなったら、無理せず手を挙げてください。
> こちらから一斉に Azure OpenAI への BYOK 切替を案内します。
> 切替の手順は `docs/05-backup-byok.md` に書いてあります。

### 4.2 個別申告 → 全員切替の判断

- 1 名が申告 → 個別に手順を案内 (最初の人が無事に切り替えられるか主催者が伴走する)
- 2 名以上が申告 / 同じセッションで複数報告 → 全員切替を発表

### 4.3 全員切替の台本

> 全員、いったん手を止めてください。
> ここから Azure OpenAI に切り替えます。
> `docs/05-backup-byok.md` の手順 3 を見ながら、Endpoint / API Key / Deployment Name を入力してください。
> 切替が終わったらチャットで `/sdd-spec` を投げて応答が返ることを確認してください。
> 5 分後に再開します。

### 4.4 レート逼迫時の対処

| 症状 | 対処 |
|---|---|
| 一部参加者が 429 (rate limit) を頻発 | スクリプトで 2 つめのリソースをデプロイ → 半分の参加者に新キー配布 |
| 全員が遅延 | CAPACITY を倍に増やして `az cognitiveservices account deployment update` で再適用 |
| モデルが応答しない | Foundry / Azure Portal の Metrics でモデル状況を確認、必要なら別モデルに deploy 切替 (例: gpt-5 → gpt-5-mini) |

## 5. コストの目安

> 実際の単価は時期・地域・SKU で変わります。**事前に Azure Pricing Calculator または `az` の course rates で見積もり** してください。

- gpt-5 系フルサイズはトークン単価が gpt-5-mini より高い (入出力ともに約 5 〜 10 倍が目安)。短時間ワークショップでも数千円規模になることがある。
- Budget Alert を必ず設定する (例: 1 日 50 USD で警告)。
- ワークショップ後にすぐ撤収すれば、当日分以上の課金は発生しない。

## 6. 撤収

ワークショップ終了後、できるだけ早く実行します。

```bash
cd scripts
RG=rg-sdd-workshop ./teardown-foundry-openai.sh
```

スクリプトは確認プロンプトを出してから `az group delete --no-wait --yes` を実行します。

撤収後は次もチェックしてください。

- 配布した API Key を再ローテーション (たとえばリソースを残す運用ならポータルから regenerate)
- Teams / 1Password 等で配布した接続情報メッセージを削除
- 自身の VS Code から、追加した Azure プロバイダー設定を削除

## 7. セキュリティ留意点

- API Key は **当日限定** の認識を徹底する。退場後にキーを保持されるリスクを認めない。
- 公開リポジトリには絶対にキー / テナント ID / サブスクリプション ID を含めない。スクリプトは環境変数を受け取り、サンプル値はダミーにする。
- ログ / 録画 / スクリーンショットにキーが映り込まないようにする。配布する画像に Endpoint / Deployment 名を含めない。
- 参加者には「ワークショップ後に VS Code から Azure プロバイダーを削除」してもらうよう案内する (`docs/05-backup-byok.md` 末尾を参照)。

## 8. 別経路: Copilot CLI のクォータが先に枯渇した場合

`.github/agents/spec-loop.agent.md` などを Copilot CLI で呼んでいる場合、それは VS Code BYOK と別系統です。CLI 側が止まった場合は次のいずれかを案内します。

- VS Code Copilot Chat の `/sdd-mockup` などで代替する (BYOK が効く)
- Foundry プレイグラウンドに `.github/prompts/sdd-*.prompt.md` を貼って実行する (二次フォールバック)

詳細は参加者向けドキュメント `docs/05-backup-byok.md` のセクション 6 / 7 を参照してください。
