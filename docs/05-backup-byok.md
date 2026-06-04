# 05. バックアッププラン: Microsoft Foundry (Azure OpenAI) BYOK

GitHub Copilot は Usage-Based Billing (UBB) によって、premium request の使用量が個人ごとに上限を持っています。180 分のワークショップでは、特に仕様生成 / モック生成 / 実装計画化を繰り返すうちに上限に達し、Copilot Chat が応答しなくなるリスクがあります。

このバックアッププランでは、**Microsoft Foundry (Azure OpenAI) のモデルを BYOK (Bring Your Own Key) で VS Code Copilot Chat に差し込み、Copilot 標準モデルが枯渇しても進行を続けられるようにします**。

## 1. 切り替えるタイミング

次のいずれかで切替を検討してください。

- 「Premium request limit reached」など、上限に近づいた / 達したという通知が出た
- チャットの応答が極端に遅くなった / エラーが連発する
- 主催者から「全員 BYOK に切り替えてください」とアナウンスがあった

> 個人で先に当たった人は、無理せず主催者に申告してください。1 〜 2 名が当たった段階で主催者が全員一斉切替の合図を出します。

## 2. 認証方式は 2 系統

主催者がどちらを使うかは事前に決まっており、当日配布される情報に **`Auth Mode`** が記載されています。

| 方式 | 配布される情報 | 想定 |
|---|---|---|
| **A. API Key** | Endpoint + Deployment Name + **API Key** | 個人 / 小規模サブスクリプション、テナントポリシーで local auth が許可されている |
| **B. Microsoft Entra ID (推奨)** | Endpoint + Deployment Name + テナント情報 (API Key なし) | エンタープライズサブスクリプション (多くの場合、テナントポリシーで API Key 認証が禁止されているためこちらが必須) |

> 配布物に API Key が **無い** 場合は方式 B です。VS Code から Entra ID にサインインして使います。

## 3. VS Code Copilot Chat に追加する手順

> 手順は VS Code 1.95 / GitHub Copilot Chat 拡張 2026 年 5 月時点のものです。UI の文言が変わっている場合は、ピッカーから「Manage Models」または「Add Model Provider」相当の項目を探してください。

### 3.1 共通手順

1. VS Code のチャットビューを開き、入力欄右下のモデルセレクタ (現在のモデル名が表示されている部分) をクリックします。
2. メニュー末尾の **「Manage Models...」** を選択します。
3. プロバイダー一覧から **「Azure」** (Azure OpenAI Service) を選択します。

### 3.2 方式 A: API Key で接続する場合

4. 次の値を入力します。
   - **Endpoint URL**: 主催者から共有された Endpoint
   - **Authentication**: `API Key` を選択
   - **API Key**: 主催者から共有された API Key
5. 接続テストが成功したら、利用可能な deployment 一覧が出るので、共有された **Deployment Name** にチェックを入れます。
6. チャットに戻り、モデルセレクタを開いて、追加した Azure モデルを選択します。

### 3.3 方式 B: Microsoft Entra ID で接続する場合

4. 次の値を入力します。
   - **Endpoint URL**: 主催者から共有された Endpoint
   - **Authentication**: `Microsoft Entra ID` (または `Azure AD`) を選択
5. ブラウザが開いて、Entra ID のサインインを求められます。**主催者から指定されたテナント** で、自分の社内アカウントでサインインします。
6. 接続テストが成功したら、利用可能な deployment 一覧が出るので、共有された **Deployment Name** にチェックを入れます。
7. チャットに戻り、モデルセレクタを開いて、追加した Azure モデルを選択します。

> サインインが「Forbidden」「No deployments available」になる場合は、ロール伝搬がまだの可能性があります。**サインアウト → サインインを 1 回挟んでから** 再試行してください。それでも改善しない場合は、主催者に「自分の UPN に `Cognitive Services OpenAI User` ロールが付いているか」を確認依頼してください。

設定は VS Code のユーザー設定に保存されます (`github.copilot.chat.byok.*` 関連)。

## 4. 動作確認

切替後、次のいずれかで動くことを確認してください。

- チャットで `/sdd-spec` と打ち、適当なユーザーストーリーを貼って仕様ドラフトが返ってくること
- カスタムエージェント `spec-author` に切り替え、仕様の問い直しが返ってくること

返答が返ってこない場合は次を確認します。

- モデルセレクタが Azure モデルになっているか (Copilot 標準に戻っていないか)
- 方式 A: API Key と Endpoint をコピペでミスしていないか (前後の空白に注意)
- 方式 B: 正しいテナントでサインインしているか、ロール伝搬を待ったか
- Deployment Name の大文字小文字が正しいか

### 4.1 CLI で動作確認したい場合 (任意)

`az` CLI が入っていれば、次の手順で API レベルの応答を確認できます。

```bash
# Entra ID 認証の場合
TOKEN=$(az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv)
curl -sS -X POST "${ENDPOINT}openai/deployments/${DEPLOYMENT_NAME}/chat/completions?api-version=2024-10-21" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Say OK"}],"max_tokens":5}'
```

```bash
# API Key 認証の場合
curl -sS -X POST "${ENDPOINT}openai/deployments/${DEPLOYMENT_NAME}/chat/completions?api-version=2024-10-21" \
  -H "api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Say OK"}],"max_tokens":5}'
```

応答に `"OK"` が含まれていれば成功です。

## 5. 制限事項

BYOK で Azure OpenAI に切り替わるのは **チャット系の動作のみ** です。次のものは BYOK 対象外なので、Copilot 標準のクォータを引き続き消費します (またはそもそも利用できません)。

| 機能 | BYOK 適用 | メモ |
|---|---|---|
| Copilot Chat (Ask / Edit / Agent モード) | あり | この BYOK で動作 |
| カスタムエージェント (`.github/agents/*.agent.md`) — VS Code | あり | モデルセレクタで Azure を選んでいれば BYOK 経由 |
| Inline 補完 (タイピング中の薄いグレーの提案) | なし | 標準モデルのまま。Copilot 上限に達すると一時停止する |
| Copilot Coding Agent (リモートで PR を作るエージェント) | なし | サーバー側で動くため BYOK 不可 |
| Copilot CLI のカスタムエージェント (`spec-loop` / `mockup-builder`) | 別途設定 | 後述「6. Copilot CLI を使う場合」を参照 |

## 6. Copilot CLI を使う場合

`.github/agents/spec-loop.agent.md` / `mockup-builder.agent.md` を Copilot CLI から呼び出している場合、これらは VS Code の BYOK 設定とは別系統です。当日 Copilot CLI 側が止まった場合は、次の二択でしのいでください。

- **VS Code Copilot Chat の `/sdd-mockup` / `/sdd-spec` で代替**
  カスタムエージェントの本文を VS Code 側で順に呼び出せば、同等のアウトプットが得られます。
- **手動コピペで Foundry プレイグラウンドへ**
  `.github/prompts/sdd-*.prompt.md` の本文をコピーし、Azure AI Foundry のプレイグラウンドに貼って実行します。`${input:...}` の部分は手動で埋めてください。

## 7. 二次フォールバック: Foundry プレイグラウンド

VS Code 自体が不調な場合や、BYOK の設定が間に合わない場合の最終手段です。

1. ブラウザで `https://ai.azure.com/` を開きます。
2. 主催者から共有されたプロジェクトを選択します (権限が必要な場合は主催者に依頼)。
3. プレイグラウンドで対象モデル (例: `gpt-4-1-prod`) を選びます。
4. `.github/prompts/sdd-spec.prompt.md` などの本文をコピーして貼り、`${input:...}` を手動で埋めて送信します。
5. 返ってきた結果を `exercises/02-spec.md` などのワークシートに転記します。

スピードは VS Code 内利用に劣りますが、ワークショップの「仕様 → 計画 → モック」サイクルは継続できます。

## 8. ワークショップ終了後

- 主催者は配布した API Key をローテーション、または Entra ID 経路の場合はロールを撤収します (リソース自体を削除する場合は不要)。
- 参加者は、VS Code の **Manage Models** で追加した Azure プロバイダーを削除しておくことを推奨します (古いキーやテナントサインインが残ったままだと次回利用時に混乱します)。

詳しい主催者側の準備手順は `facilitator/byok-setup.md` を参照してください (ファシリテーター専用)。
