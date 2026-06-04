# BYOK バックアップ運用ガイド (主催者専用)

GitHub Copilot のクォータがワークショップ中に枯渇するリスクへの備えとして、Microsoft Foundry (Azure OpenAI) を BYOK で参加者に開放する運用手順です。参加者向けの切替手順は `../docs/05-backup-byok.md` を参照してください。

## 0. 認証方式の選択 (重要)

Azure OpenAI へのアクセス方式は次の 2 つがあります。**テナント / サブスクリプションのポリシー次第で選べる方式が決まります**。

| 方式 | 配布物 | 適合シナリオ |
|---|---|---|
| **A. API Key** | Endpoint + Deployment Name + API Key | 個人 Pay-As-You-Go、テナントポリシーで API キー認証が許可されている |
| **B. Microsoft Entra ID** | Endpoint + Deployment Name + テナント情報 + 参加者 UPN ごとのロール付与 | エンタープライズサブスクリプション (多くの場合、`disableLocalAuth=true` が Azure Policy で強制されているため必須) |

### 自動判別

`scripts/deploy-foundry-openai.sh` は実行時に `disableLocalAuth` を `false` に変更しようと試み、ポリシーで拒否された場合は自動的に方式 B にフォールバックします。出力末尾の `Auth Mode:` を確認してください。

### 事前確認方法

実行前に方式を確認したい場合:

```bash
az policy state list \
  --filter "ComplianceState eq 'Compliant'" \
  --query "[?contains(policyDefinitionName, 'LocalAuth') || contains(policyDefinitionAction, 'modify')].{policy:policyDefinitionName, effect:policyDefinitionAction}" \
  -o table
```

`CognitiveServices_LocalAuth_Modify` (modify) が出てくる場合 → 方式 B 必須。

## 1. 事前準備チェックリスト

- [ ] Azure サブスクリプションがあり、Owner または Contributor 権限を持っている
- [ ] サブスクリプションで Azure OpenAI / Foundry の利用が承認済み (新規テナントは申請が必要なことがある)
- [ ] 利用したいモデルの **TPM クォータが 0 ではない** ことを確認した
  - 確認: `az cognitiveservices usage list --location eastus2 -o table | grep -i gpt`
  - 0 の場合: Azure Portal の Quotas からクォータ申請、または利用可能な別モデル (gpt-4.1, gpt-4o, gpt-4o-mini) にフォールバック
- [ ] `az` CLI がインストール済み (v2.60 以上推奨、できれば v2.86 以上)
- [ ] `az login` 済みで、`az account show` で正しいサブスクリプションが選ばれている
- [ ] **方式 B の場合**: 参加者の UPN (Entra ID のメールアドレス) を全員分集めた
- [ ] **方式 B の場合**: 自分が対象アカウントの Owner または User Access Administrator である (ロール付与のため)
- [ ] Budget Alert を設定する予定があるか決めた (推奨)
- [ ] 配布チャネルを決めた (Teams プライベートチャット / 1Password 共有、公開チャンネル禁止)

## 2. 1 コマンドでデプロイ

リポジトリ同梱の `scripts/deploy-foundry-openai.sh` を使うと、リソースグループ作成 → AIServices アカウント作成 → モデル deploy → 接続情報出力までを 1 コマンドで実行できます。

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

実行後、`.env.workshop` ファイル (gitignore 済) と標準出力に、参加者へ配布する情報が出力されます。出力末尾の `Auth Mode:` が `apikey` か `entra` かで、続く手順が変わります。

### よくあるパラメータ

| 環境変数 | 既定値 | 説明 |
|---|---|---|
| `RG` | `rg-sdd-workshop` | リソースグループ名 |
| `LOCATION` | `eastus2` | Azure リージョン |
| `RESOURCE_NAME` | `aoai-sdd-workshop` | AIServices アカウント名。グローバルに一意 |
| `DEPLOYMENT_NAME` | `gpt-5-prod` | VS Code BYOK で指定する deployment 名 |
| `MODEL_NAME` | `gpt-5` | Azure モデル ID。クォータがなければ `gpt-5-mini` / `gpt-4.1` / `gpt-4o` |
| `MODEL_VERSION` | (空) | 省略時はリージョンで利用可能な最新版を自動取得 |
| `SKU` | `GlobalStandard` | deployment SKU |
| `CAPACITY` | `200` | TPM (千トークン/分)。参加人数に応じて調整 |

### モデル選択のフォールバック順

`gpt-5` / `gpt-5.4` / `gpt-5.5` 系は新しいため、`InsufficientQuota` エラーが出ることがあります。次の順でフォールバックしてください。

1. `gpt-5` → 失敗なら
2. `gpt-5-mini` → 失敗なら
3. `gpt-4.1` (検証済み 2025-04-14 版) → 失敗なら
4. `gpt-4o`

### TPM の目安

| 参加人数 | 想定 CAPACITY (千 TPM) | 補足 |
|---:|---:|---|
| 〜 5 名 | 100 | リハーサルや小規模 |
| 6 〜 10 名 | 200 | 標準 |
| 11 〜 20 名 | 400 | 余裕を持たせる |
| 21 名〜 | 800 + 別リソース併用 | 複数リソースに分散する |

足りないと感じたら、同じスクリプトで `RESOURCE_NAME` を変えてもう一つデプロイし、参加者を半分ずつに割り振る運用が手堅いです。

## 3. 接続情報の配布

### 3.1 方式 A (API Key) の場合

配布物 (3 点):

```
件名: 【SDD ワークショップ】BYOK 切替時の接続情報
本文:
  Endpoint:        https://aoai-sdd-workshop.openai.azure.com/
  Deployment Name: gpt-5-prod
  API Key:         <ここに記載>
  有効期限:        本日のワークショップ終了まで
  使い方:          docs/05-backup-byok.md セクション 3.2
```

- **NG**: 公開チャンネル / 共有ドキュメント / GitHub Issue / PR / コミット
- **OK**: Teams プライベートチャット、1Password 共有金庫、紙配布

### 3.2 方式 B (Entra ID) の場合

事前にロール付与が必要です。参加者の UPN リストを集めて、次を実行してください。

```bash
cd scripts
RG=rg-sdd-workshop \
RESOURCE_NAME=aoai-sdd-workshop \
USERS="alice@example.com bob@example.com carol@example.com" \
./grant-workshop-access.sh
```

または、リストをファイルにまとめて:

```bash
USER_LIST_FILE=workshop-users.txt ./grant-workshop-access.sh
```

スクリプトは各 UPN に `Cognitive Services OpenAI User` ロールをアカウントスコープで付与します。idempotent なので何度実行してもよいです。

配布物 (3 点、API Key 不要):

```
件名: 【SDD ワークショップ】BYOK 切替時の接続情報 (Entra ID)
本文:
  Endpoint:        https://aoai-sdd-workshop.cognitiveservices.azure.com/
  Deployment Name: gpt-5-prod
  Auth Mode:       Microsoft Entra ID
  Tenant:          <テナント名 or テナント ID>
  あなたの UPN:    (受け取った人の社内メールアドレス)
  使い方:          docs/05-backup-byok.md セクション 3.3
```

Entra ID 方式は配布物自体に秘密情報が含まれないため、Teams のグループチャットでも配布可能です (Endpoint / Deployment / テナントが社外秘でない前提)。それでも UPN リストとロール付与のスコープは記録しておきましょう。

### 3.3 ロール伝搬の注意

`az role assignment create` 直後は伝搬に数分かかります。参加者には次を案内してください。

- 「**サインアウト → サインインを 1 回挟む** と確実に反映されます」
- 「`Forbidden` や `No deployments available` が出たら 1〜2 分待って再試行」

## 4. 当日の運用

### 4.1 オープニング (0:00 - 0:10)

参加者に次を 1 分でアナウンスします。

> Copilot が応答しなくなったら、無理せず手を挙げてください。
> こちらから一斉に Azure OpenAI への BYOK 切替を案内します。
> 切替の手順は `docs/05-backup-byok.md` に書いてあります。
> 認証方式は **A. API Key** / **B. Entra ID** のどちらかで、配布された情報に書いてあります。

### 4.2 個別申告 → 全員切替の判断

- 1 名が申告 → 個別に手順を案内 (最初の人が無事に切り替えられるか主催者が伴走する)
- 2 名以上が申告 / 同じセッションで複数報告 → 全員切替を発表

### 4.3 全員切替の台本

#### 方式 A (API Key) の場合

> 全員、いったん手を止めてください。
> ここから Azure OpenAI に切り替えます。
> `docs/05-backup-byok.md` の手順 3.2 を見ながら、Endpoint / API Key / Deployment Name を入力してください。
> 切替が終わったらチャットで `/sdd-spec` を投げて応答が返ることを確認してください。
> 5 分後に再開します。

#### 方式 B (Entra ID) の場合

> 全員、いったん手を止めてください。
> ここから Azure OpenAI (Entra ID 認証) に切り替えます。
> `docs/05-backup-byok.md` の手順 3.3 を見ながら、Endpoint と Deployment Name を入力し、
> 認証方式に Entra ID を選んで、配布したテナントの自分のアカウントでサインインしてください。
> サインインできない場合は、サインアウト → サインインを 1 回挟んで再試行してください。
> 切替が終わったらチャットで `/sdd-spec` を投げて応答が返ることを確認してください。
> 5 分後に再開します。

### 4.4 レート逼迫時の対処

| 症状 | 対処 |
|---|---|
| 一部参加者が 429 (rate limit) を頻発 | スクリプトで 2 つめのリソースをデプロイ → 半分の参加者に新キー / 新リソースの情報を配布 |
| 全員が遅延 | CAPACITY を倍に増やして `az cognitiveservices account deployment update` で再適用 |
| モデルが応答しない | Foundry / Azure Portal の Metrics でモデル状況を確認、必要なら別モデルに deploy 切替 (例: gpt-5 → gpt-5-mini) |
| 一部の人だけ Forbidden | 方式 B でロール伝搬遅延の可能性。`grant-workshop-access.sh` を再実行 + サインアウト/サインイン |

## 5. コストの目安

> 実際の単価は時期・地域・SKU で変わります。**事前に Azure Pricing Calculator または `az` の course rates で見積もり** してください。

- gpt-5 系フルサイズはトークン単価が gpt-5-mini より高い (入出力ともに約 5 〜 10 倍が目安)。短時間ワークショップでも数千円規模になることがある。
- Budget Alert を必ず設定する (例: 1 日 50 USD で警告)。
- ワークショップ後にすぐ撤収すれば、当日分以上の課金は発生しない。

## 6. 撤収

ワークショップ終了後、できるだけ早く実行します。

### 6.1 リソースごと削除 (最も簡単)

```bash
cd scripts
RG=rg-sdd-workshop ./teardown-foundry-openai.sh
```

リソースグループを削除すれば、ロール割り当て、デプロイ、API キーすべてが消えます。

### 6.2 リソースを残してロールだけ撤収 (継続利用したい場合)

```bash
cd scripts
RG=rg-sdd-workshop \
RESOURCE_NAME=aoai-sdd-workshop \
USERS="alice@example.com bob@example.com carol@example.com" \
./revoke-workshop-access.sh
```

API Key を継続利用する場合は、`az cognitiveservices account keys regenerate --key-name key1` でローテーションも推奨します。

### 6.3 共通の後片付け

- Teams / 1Password 等で配布した接続情報メッセージを削除
- 自身の VS Code から、追加した Azure プロバイダー設定を削除

## 7. セキュリティ留意点

- API Key (方式 A) は **当日限定** の認識を徹底する。退場後にキーを保持されるリスクを認めない。
- Entra ID (方式 B) はロールベース。撤収忘れがあると参加者は退場後もアクセスできてしまうので、`revoke-workshop-access.sh` を必ず実行する (またはリソース削除)。
- 公開リポジトリには絶対にキー / テナント ID / サブスクリプション ID / UPN リストを含めない。スクリプトは環境変数を受け取り、サンプル値はダミーにする。
- ログ / 録画 / スクリーンショットにキーや UPN が映り込まないようにする。
- 参加者には「ワークショップ後に VS Code から Azure プロバイダーを削除」してもらうよう案内する (`docs/05-backup-byok.md` 末尾を参照)。

## 8. 別経路: Copilot CLI のクォータが先に枯渇した場合

`.github/agents/spec-loop.agent.md` などを Copilot CLI で呼んでいる場合、それは VS Code BYOK と別系統です。CLI 側が止まった場合は次のいずれかを案内します。

- VS Code Copilot Chat の `/sdd-mockup` などで代替する (BYOK が効く)
- Foundry プレイグラウンドに `.github/prompts/sdd-*.prompt.md` を貼って実行する (二次フォールバック)

詳細は参加者向けドキュメント `../docs/05-backup-byok.md` のセクション 6 / 7 を参照してください。

## 9. 既知の落とし穴

実運用で踏んだ事例:

| 事象 | 原因 | 回避策 |
|---|---|---|
| `InsufficientQuota` でモデル deploy 失敗 | サブスクリプションでそのモデルの TPM クォータが 0 | 別モデルにフォールバック (gpt-5 → gpt-4.1) または Azure Portal でクォータ申請 |
| `Failed to list key. disableLocalAuth is set to be true` | テナントポリシー `CognitiveServices_LocalAuth_Modify` が API キー認証を禁止 | 方式 B (Entra ID) を使う |
| `--model-version` 必須エラー | az CLI v2.86+ で必須化された | スクリプトは自動取得するので最新版を使用 |
| 参加者が `Forbidden` を連発 | ロール伝搬遅延 | サインアウト / サインインを案内、または再実行 |
| 設置時点の `Endpoint` が `*.openai.azure.com` ではなく `*.cognitiveservices.azure.com` | `AIServices` kind (Foundry 互換) なため | どちらでも VS Code BYOK は受け付ける |
