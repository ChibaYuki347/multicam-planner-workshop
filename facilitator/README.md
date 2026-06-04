# facilitator/

ファシリテーター（主催者・進行担当）専用のドキュメントを置くフォルダです。

**参加者に配布する想定ではない** ため、事前案内に含めたり、当日のリポジトリ共有 URL に含めるときは扱いを分けてください。

## 含まれるもの

| ファイル | 内容 |
|---|---|
| `agenda.md` | 180 分タイムテーブルと進行台本 (BYOK コンティンジェンシー含む) |
| `byok-setup.md` | Microsoft Foundry (Azure OpenAI) BYOK バックアップの主催者向け運用ガイド |
| `opening-slide.html` | オープニング (0:00 - 0:10) で投影する 1 枚スライド (単一 HTML, 16:9) |
| `running-online.md` | オンライン / ハイブリッド開催時の運営注意 |

ファシリテーターも、ワークショップ実演中の最短ルートは `../docs/06-quickstart-flow.md` を見てください。

## 参加者と共有するもの

参加者向けには次のフォルダ / ファイルを案内してください。

- `../README.md`
- `../docs/00-overview.md`（ワークショップの全体像）
- `../docs/01-theme.md`（題材）
- `../docs/02-participant-prep.md`（事前準備）
- `../docs/03-copilot-prompts.md`（手動コピペ用プロンプト原文 / 二次フォールバック）
- `../docs/04-custom-prompts-and-agents.md`（カスタムスキル全体のリファレンス）
- `../docs/05-backup-byok.md`（Copilot クォータ枯渇時の BYOK 切替手順）
- `../docs/06-quickstart-flow.md`（最短ルート: sdd-guide で 1 文から仕様まで）
- `../exercises/`（ワークシート群）
- `../mockups/`（合意用 HTML モックアップ）

## 公開リポジトリにする場合の選択肢

- このフォルダごと公開して、ファシリテーターガイドのテンプレートとして使ってもらう
- 公開前に `facilitator/` を別リポジトリ（プライベート）に分離する
- `facilitator/` を `.gitignore` に追加して公開リポジトリには含めない

どれを選ぶかは主催側の方針に合わせて決めてください。
