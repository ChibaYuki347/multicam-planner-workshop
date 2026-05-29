# Multi-Camera Capture Planner — プロトタイプ雛形

ワークショップで使う Next.js (App Router) + TypeScript のスターターです。

## できること (最初の状態)

- 上面図 (SVG) にステージ・被写体・メインカメラ・俯瞰カメラを表示する
- カメラを選択すると、撮影意図 / 担当被写体 / 画角 / 距離 を表示する
- モックデータ (`lib/mock.ts`) を編集することで構図を切り替えられる

## できないこと (意図的に未実装)

- カメラ / 被写体 / ステージのドラッグ移動
- シーンの保存 / 読み込み
- 複数シーンの切り替え
- 本物のカメラ制御 / API 連携
- 3D ビュー

これらは **ワークショップの題材** です。Copilot と一緒に追加していきます。

## クイックスタート

```bash
npm install
npm run dev
# http://localhost:3000
```

ビルド / 型チェック / Lint:

```bash
npm run build
npm run typecheck
npm run lint
```

## ディレクトリ

```
prototype/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── globals.css
│   └── components/
│       ├── StageMap.tsx       # 上面図 (SVG)
│       ├── CameraPanel.tsx    # カメラ一覧
│       └── IntentCard.tsx     # 選択中カメラの撮影意図
├── lib/
│   ├── types.ts               # ドメインモデル
│   └── mock.ts                # 既定シーン
├── package.json
├── tsconfig.json
└── next.config.mjs
```

## 拡張するときのヒント

- まず `lib/types.ts` と `lib/mock.ts` を読んで、何が表現できるかを把握する。
- 大きな変更を入れる前に、`exercises/02-spec.md` に仕様を書いてからコーディングする。
- 状態管理は当面 `useState` で十分。複雑になってきたら `useReducer` への移行を Copilot に提案させる。
