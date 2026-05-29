# 04. カスタムプロンプトとカスタムエージェントの使い方

仕様駆動開発の各ステップを **半自動化** するための、プロンプト・カスタムエージェント・スコープ別命令を同梱しています。VS Code Copilot Chat と GitHub Copilot CLI のどちらからも使えます。

## 全体マップ

| やりたいこと | 推奨スキル | 種別 |
|---|---|---|
| 曖昧な要望からユーザーストーリーを 3 本作る | `/sdd-user-story` | プロンプト |
| ユーザーストーリーから仕様を作る | `/sdd-spec` | プロンプト |
| 仕様から実装計画を作る | `/sdd-plan` | プロンプト |
| 仕様から HTML モックアップを作る | `/sdd-mockup` | プロンプト |
| ビジネスレビュアー視点でフィードバックする | `/sdd-business-review` | プロンプト |
| 実装計画 1 件を Copilot 用作業指示にする | `/sdd-task` | プロンプト |
| 仕様化フェーズに集中して会話する | `spec-author` カスタムエージェント | カスタムエージェント |
| 仕様 / モックを業務側目線でレビューする | `business-reviewer` カスタムエージェント | カスタムエージェント |
| `prototype/` に最小差分で実装する | `prototype-builder` カスタムエージェント | カスタムエージェント |
| `prototype/` を編集するときの追加規約 | `prototype.instructions.md` | スコープ命令 |
| `mockups/` を作るときの追加規約 | `mockup.instructions.md` | スコープ命令 |
| 仕様 → モック → セルフレビュー → 改訂を 1 周回す | `.github/agents/spec-loop.agent.md` | Copilot CLI カスタムエージェント |
| 仕様 1 本からモックを 1 ファイル作る | `.github/agents/mockup-builder.agent.md` | Copilot CLI カスタムエージェント |

## VS Code Copilot Chat での使い方

このリポジトリを VS Code で開くと、`.github/` 配下のファイルが自動的に Copilot Chat に取り込まれます。

### スラッシュコマンド (プロンプト)

チャット欄に `/` を打つと、`sdd-` で始まるコマンドが候補に出ます。

```
/sdd-user-story       曖昧な要望からユーザーストーリーを 3 本生成
/sdd-spec             ユーザーストーリーをプロトタイプ向け仕様に展開
/sdd-plan             仕様を Next.js プロトタイプの実装計画に分解
/sdd-mockup           仕様から、合意用の単一 HTML モックアップを生成
/sdd-business-review  ビジネスレビュアー視点でフィードバック
/sdd-task             実装計画のタスク 1 件を Copilot 用指示に整形
```

### カスタムエージェント (`.github/agents/*.agent.md`)

エージェント (旧チャットモード) のピッカーから、次のいずれかを選びます。

```
spec-author          仕様化フェーズに集中。コード実装には踏み込まない。
business-reviewer    ビジネスレビュアーとして振る舞う。技術選定は議論しない。
prototype-builder    prototype/ 配下に最小差分で実装する。
```

役割ごとに `tools` が異なります (例: `spec-author` は読み取りのみ、`prototype-builder` はファイル編集とターミナル実行を含む)。詳細は各ファイル冒頭の YAML フロントマターを参照してください。

### スコープ別命令 (自動適用)

VS Code Copilot Chat / Edit セッションがファイルを編集するとき、対象パスに応じて自動で追加指示が当たります。

- `prototype/**/*.{ts,tsx,css}` → `.github/instructions/prototype.instructions.md`
- `mockups/**/*.html` → `.github/instructions/mockup.instructions.md`

ワークショップ参加者は、これらのファイルを直接読む必要はありません。Copilot が自動で参照します。

## GitHub Copilot CLI での使い方

Copilot CLI から、`.agent.md` で定義したマルチステップエージェントを 1 コマンドで起動できます (`.github/agents/spec-loop.agent.md`、`.github/agents/mockup-builder.agent.md`)。

```bash
# このリポジトリ直下で
copilot --agent .github/agents/spec-loop.agent.md "ユーザーストーリー: 上面図でカメラを選ぶと、担当被写体と意図がカードで読める"

copilot --agent .github/agents/mockup-builder.agent.md "exercises/02-spec.md の仕様からモックを作って"
```

> Copilot CLI のエージェント指定方法はバージョンによって異なります。`copilot --help` で `--agent` オプションを確認するか、ユーザーレベルの設定ディレクトリ (`~/.copilot/agents/` など) に `*.agent.md` をコピーしてからエージェント名で呼び出してください。

VS Code 用カスタムエージェント (`spec-author` / `business-reviewer` / `prototype-builder`) と、Copilot CLI 用エージェント (`spec-loop` / `mockup-builder`) は **どちらも `.github/agents/` に同居** しています。利用するクライアントによって使い分けてください。

## 推奨フロー

### 個人ペース (リハーサル)

1. `/sdd-user-story` で 3 本作る
2. 1 本選んで `/sdd-spec`
3. `/sdd-mockup` でモックを `mockups/` に書き出す
4. ブラウザでモックを開き、自分で `/sdd-business-review` を実行
5. 修正版を作り、`/sdd-plan` → `/sdd-task` で実装可能な形に落とす

### グループワーク (3 時間ワークショップ)

1. ビジネスレビュアーが要望を口頭で出す
2. ナビゲーターが `/sdd-user-story` を実行し、3 本のうち 1 本を全員で選ぶ
3. 仕様化と業務レビューを並行
   - 開発側: `spec-author` カスタムエージェントに切り替えて `/sdd-spec`
   - 業務側: モックが出てきたら `business-reviewer` カスタムエージェントでフィードバック
4. 合意したら `/sdd-plan` → `/sdd-task` → `prototype-builder` カスタムエージェントで実装
5. レビュー → 改善を 1 周回す

### 半自動ループ (1 人で短時間で回したいとき)

```bash
copilot --agent .github/agents/spec-loop.agent.md "ユーザーストーリーの要約 ..."
```

1 回の起動で、仕様 → モック → セルフレビュー → 改訂 → go/no-go までを最大 2 周回します。

## 拡張のヒント

- 自社の題材に置き換える場合は、各ファイル冒頭の「マルチカメラ撮影プランナー（架空題材）」をドメイン名に差し替えるだけで再利用できます。
- 新しいスキルを増やしたいときは、次の場所に追加してください。
  - 1 ステップで完結するプロンプト → `.github/prompts/sdd-<name>.prompt.md`
  - 会話全体の振る舞いを変えるカスタムエージェント → `.github/agents/<role>.agent.md`
  - 編集対象パスに応じた追加指示 → `.github/instructions/<scope>.instructions.md`
  - 複数ステップを 1 コマンドで → `.github/agents/<name>.agent.md` (CLI 起動を前提とした多段エージェント)
