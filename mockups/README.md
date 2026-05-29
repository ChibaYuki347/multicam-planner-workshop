# mockups/

ビジネスユーザーと「合意するため」に使う、軽量 HTML モックアップの置き場です。

## ポリシー

- **単一 HTML ファイル** で完結すること。外部 CSS / JS / 画像 / フォントを参照しない。
- 装飾はインライン `<style>`、図は `<svg>` で表現する。
- ファイル名は kebab-case + `.html`。例: `camera-intent-card.html`。
- 個社・実在製品・個人名は使わない (架空名 Acme Studio などを使う)。
- 1 ファイルの目安は 200 〜 400 行。超えたら画面を分割する。

詳細な制約は `.github/instructions/mockup.instructions.md` を参照してください。

## 含めるべき構成

各モックアップは次の構成を含めてください。

1. `<header>`
   - タイトル
   - 想定ユーザー
   - 扱う範囲 / 扱わない範囲
   - 「これはモックアップであり、実装ではありません」の注記
2. 主要ビュー (SVG または HTML)
3. 補足カード (操作結果、選択中の意図など)
4. 受け入れ条件チェックリスト (仕様から転記)

## 参考実装

- `example-camera-intent.html` — Multi-Camera Capture Planner の「カメラ別意図表示カード」モック。粒度の参考にしてください。

## 生成方法

- VS Code Copilot Chat で `/sdd-mockup` を実行する (`.github/prompts/sdd-mockup.prompt.md`)
- もしくは Copilot CLI で `.github/agents/mockup-builder.agent.md` を呼び出す

## レビュー方法

1. ファシリテーターが対象の `.html` をブラウザで開いて画面共有する。
2. ビジネスレビュアーに次の質問を投げる。
   - これで現場でやりたいことが分かりますか
   - 足りない情報はありますか
   - 順番や強弱は妥当ですか
3. フィードバックを `.github/prompts/sdd-business-review.prompt.md` (または `business-reviewer` カスタムエージェント) に渡し、改訂指示を生成する。
4. `/sdd-mockup` または `mockup-builder` エージェントで上書き再生成する。
