# Spec-Driven Development Workshop: Multi-Camera Capture Planner

GitHub Copilot を使って **「要件 → ユーザーストーリー → 仕様 → 実装計画 → プロトタイプ → レビュー」** を 180 分で回す、仕様駆動開発（Spec-Driven Development, SDD）ワークショップのテンプレートです。

題材は架空の「マルチカメラ撮影プランナー」。複数台の IP 制御カメラと被写体・俯瞰カメラを上面図で設計し、各カメラのショット意図を事前確認できる Web アプリを作っていきます。

> **このリポジトリの目的**
> - 仕様駆動開発を、ビジネスロールと開発ロールが同じ部屋で体験するための雛形を提供する。
> - Copilot を「コード生成器」ではなく「仕様化・計画化・実装・レビューの伴走者」として使う流れを示す。
> - 3 時間で 1 〜 2 サイクル回せる粒度の題材とサンプル UI を用意する。

## このリポジトリで提供するもの

| 種別 | 内容 |
|---|---|
| ドキュメント | ワークショップ題材、ファシリテーター向け進行、参加者向け事前準備、Copilot プロンプト集 |
| ワークシート | ユーザーストーリー、仕様、実装計画、プロトタイプメモ、レビュー記録の各テンプレート |
| プロトタイプ雛形 | Next.js (App Router, TypeScript) ベースのスターター。上面図 SVG、カメラ選択 UI、モックデータ付き |
| カスタムスキル | VS Code Copilot Chat / GitHub Copilot CLI 共通のカスタムエージェント、スラッシュコマンド、スコープ命令 (詳細: `docs/04-custom-prompts-and-agents.md`) |
| 合意用モック | `mockups/` 配下の単一 HTML モックアップとサンプル |
| BYOK バックアップ | Copilot クォータ枯渇に備えた Microsoft Foundry (Azure OpenAI) 切替手順とデプロイスクリプト (`docs/05-backup-byok.md` / `scripts/`) |

## ディレクトリ構成

```
.
├── README.md                  # この資料
├── docs/                      # 参加者にも共有するドキュメント
│   ├── 00-overview.md         # ワークショップの全体像
│   ├── 01-theme.md            # 題材の前提と用語
│   ├── 02-participant-prep.md # 参加者の事前準備
│   ├── 03-copilot-prompts.md  # 段階別 Copilot プロンプト集 (手動コピペ用)
│   ├── 04-custom-prompts-and-agents.md  # スラッシュコマンド / カスタムエージェントの使い方
│   └── 05-backup-byok.md      # Copilot クォータ枯渇時の BYOK 切替手順 (参加者向け)
├── facilitator/               # 主催者・進行担当のみが見るフォルダ
│   ├── README.md              # 取扱方針
│   ├── agenda.md              # 180分タイムテーブル / 進行台本
│   ├── byok-setup.md          # BYOK バックアップ運用ガイド (主催者向け)
│   └── running-online.md      # オンライン / ハイブリッド運営の注意
├── exercises/                 # 配布用ワークシート
│   ├── 01-user-stories.md
│   ├── 02-spec.md
│   ├── 03-implementation-plan.md
│   ├── 04-prototype.md
│   └── 05-review.md
├── mockups/                   # ビジネス合意用の単一 HTML モックアップ
│   ├── README.md
│   └── example-camera-intent.html
├── scripts/                   # 主催者向け運用スクリプト (Azure OpenAI デプロイ / 撤収)
│   ├── README.md
│   ├── deploy-foundry-openai.sh
│   └── teardown-foundry-openai.sh
├── prototype/                 # Next.js プロトタイプ雛形
│   ├── README.md
│   └── (app/, lib/, package.json ほか)
└── .github/
    ├── copilot-instructions.md          # Copilot 共通規約
    ├── prompts/sdd-*.prompt.md          # VS Code Copilot Chat 用スラッシュコマンド
    ├── agents/*.agent.md                # カスタムエージェント (VS Code 用ロール / Copilot CLI 用マルチステップ)
    └── instructions/*.instructions.md   # 編集対象パスに応じて自動適用される追加指示
```

## ワークショップの流れ（180 分）

| 時間 | セッション |
|---:|---|
| 0:00 - 0:10 | オープニング |
| 0:10 - 0:25 | 題材の現状共有 |
| 0:25 - 0:45 | 既存ツール観察（ライブデモ） |
| 0:45 - 1:05 | ユーザーストーリー化 |
| 1:05 - 1:25 | Copilot で仕様化 |
| 1:25 - 1:35 | 休憩 |
| 1:35 - 1:55 | 実装計画化 |
| 1:55 - 2:25 | プロトタイプ生成 |
| 2:25 - 2:45 | レビューと改善 |
| 2:45 - 3:00 | まとめ |

詳細は [`facilitator/agenda.md`](facilitator/agenda.md) を参照してください（ファシリテーター専用）。

## クイックスタート

```bash
# プロトタイプ雛形を起動
cd prototype
npm install
npm run dev
# http://localhost:3000 を開く
```

参加者の事前準備は [`docs/02-participant-prep.md`](docs/02-participant-prep.md) を、
カスタムスキル一覧と使い方は [`docs/04-custom-prompts-and-agents.md`](docs/04-custom-prompts-and-agents.md) を参照してください。

ワークショップ中に GitHub Copilot のクォータが枯渇した場合のバックアップは [`docs/05-backup-byok.md`](docs/05-backup-byok.md) (参加者向け) と [`facilitator/byok-setup.md`](facilitator/byok-setup.md) (主催者向け) にまとめてあります。

## ライセンスと利用範囲

このリポジトリはワークショップ運営テンプレートとして自由に複製・改変できます。配布物に特定企業・特定製品・個人名は含まれていません。各組織のドメインに合わせて題材や用語を差し替えて利用してください。
