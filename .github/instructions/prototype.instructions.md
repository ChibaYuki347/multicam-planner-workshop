---
applyTo: 'prototype/**/*.{ts,tsx,css}'
---

`prototype/` 配下の変更に適用する追加指示です。

- Next.js 14 App Router + TypeScript + React 18 を前提にする。
- 関数コンポーネントと `useState` / `useReducer` を基本にする。クラスコンポーネントや `useEffect` での副作用は最小限にする。
- ドメインモデルは `prototype/lib/types.ts` の Stage / Subject / Camera / OverheadCamera / Scene を中心に据え、必要なら拡張する形で型を追加する。互換性のない破壊変更は避ける。
- モックデータは `prototype/lib/mock.ts` に集約する。コンポーネント内に直書きしない。
- 外部 API 呼び出し、認証、ルーティング以外の Next.js 専有機能 (server actions など) は本ワークショップの範囲外。
- 新しい npm 依存を追加する前に、本当に必要かを 2 行で説明する。
- スタイルは `prototype/app/globals.css` を優先する。新しい CSS ファイルを増やすときは命名規約 (component-name 単位の class 名) を維持する。
- 文字列・サンプルデータでは実在企業・実在製品・個人名を使わない。架空の `Acme Studio` / `Performer A` / `Cam 1` などを使う。
