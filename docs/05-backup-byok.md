# 05. バックアッププラン: Microsoft Foundry (Azure OpenAI) BYOK

GitHub Copilot は Usage-Based Billing (UBB) によって、premium request の使用量が個人ごとに上限を持っています。180 分のワークショップでは、特に仕様生成 / モック生成 / 実装計画化を繰り返すうちに上限に達し、Copilot Chat が応答しなくなるリスクがあります。

このバックアッププランでは、**Microsoft Foundry (Azure OpenAI) のモデルを BYOK (Bring Your Own Key) で VS Code Copilot Chat に差し込み、Copilot 標準モデルが枯渇しても進行を続けられるようにします**。

## 1. 切り替えるタイミング

次のいずれかで切替を検討してください。

- 「Premium request limit reached」など、上限に近づいた / 達したという通知が出た
- チャットの応答が極端に遅くなった / エラーが連発する
- 主催者から「全員 BYOK に切り替えてください」とアナウンスがあった

> 個人で先に当たった人は、無理せず主催者に申告してください。1 〜 2 名が当たった段階で主催者が全員一斉切替の合図を出します。

## 2. 必要なもの

主催者から、次の 3 点が共有されます。

| 項目 | 例 | 用途 |
|---|---|---|
| Azure OpenAI Endpoint | `https://aoai-workshop-eastus2.openai.azure.com/` | API のエンドポイント |
| API Key | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | 認証キー |
| Deployment Name | `gpt-5-prod` | VS Code から呼び出すモデルの deployment 名 |

> **キーは個人配布物です。** Slack / Teams のパブリックチャンネル、画面共有、コミットには絶対に貼らないでください。当日のみ有効で、ワークショップ後にローテーション / 削除されます。

## 3. VS Code Copilot Chat に追加する手順

> 手順は VS Code 1.95 / GitHub Copilot Chat 拡張 2026 年 5 月時点のものです。UI の文言が変わっている場合は、ピッカーから「Manage Models」または「Add Model Provider」相当の項目を探してください。

1. VS Code のチャットビューを開き、入力欄右下のモデルセレクタ (現在のモデル名が表示されている部分) をクリックします。
2. メニュー末尾の **「Manage Models...」** を選択します。
3. プロバイダー一覧から **「Azure」** (Azure OpenAI Service) を選択します。
4. 次の値を入力します。
   - **Endpoint URL**: 主催者から共有された Endpoint
   - **API Key**: 主催者から共有された API Key
5. 接続テストが成功したら、利用可能な deployment 一覧が出るので、共有された **Deployment Name** にチェックを入れます。
6. チャットに戻り、モデルセレクタを開いて、追加した Azure モデルを選択します。

設定は VS Code のユーザー設定に保存されます (`github.copilot.chat.byok.*` 関連)。

## 4. 動作確認

切替後、次のいずれかで動くことを確認してください。

- チャットで `/sdd-spec` と打ち、適当なユーザーストーリーを貼って仕様ドラフトが返ってくること
- カスタムエージェント `spec-author` に切り替え、仕様の問い直しが返ってくること

返答が返ってこない場合は次を確認します。

- モデルセレクタが Azure モデルになっているか (Copilot 標準に戻っていないか)
- API Key と Endpoint をコピペでミスしていないか (前後の空白に注意)
- Deployment Name の大文字小文字が正しいか

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
3. プレイグラウンドで対象モデル (例: `gpt-5-prod`) を選びます。
4. `.github/prompts/sdd-spec.prompt.md` などの本文をコピーして貼り、`${input:...}` を手動で埋めて送信します。
5. 返ってきた結果を `exercises/02-spec.md` などのワークシートに転記します。

スピードは VS Code 内利用に劣りますが、ワークショップの「仕様 → 計画 → モック」サイクルは継続できます。

## 8. ワークショップ終了後

- 主催者は配布した API Key をローテーションまたはリソース削除します。
- 参加者は、VS Code の **Manage Models** で追加した Azure プロバイダーを削除しておくことを推奨します (古いキーが残ったままだと次回利用時に混乱します)。

詳しい主催者側の準備手順は `facilitator/byok-setup.md` を参照してください (ファシリテーター専用)。
