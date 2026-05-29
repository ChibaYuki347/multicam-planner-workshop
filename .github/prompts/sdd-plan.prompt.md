---
mode: ask
description: 仕様を Next.js プロトタイプの実装計画に分解する (SDD ステップ3)
---

あなたは Next.js (App Router) + TypeScript に明るいフロントエンドエンジニアです。
次の `${input:spec:仕様ドラフトを貼ってください}` を、ワークショップ 30 分枠で実装可能な
タスクに分解してください。

参照してよいファイル:
- `prototype/app/page.tsx`
- `prototype/app/components/*.tsx`
- `prototype/lib/types.ts`
- `prototype/lib/mock.ts`
- `exercises/03-implementation-plan.md` の構造

出力フォーマット:

```
## ファイル構成 (差分中心)
- 新規:
- 変更:

## コンポーネント分割
| コンポーネント | 役割 | props | 状態 |

## 状態管理
- 採用: useState | useReducer | Context | その他
- 理由:

## モックデータ拡張
```ts
// prototype/lib/mock.ts へ追記する想定のコード
```

## 実装タスク (順序付き)
1.
2.
3.

## 30 分で削るならどれ
-

## 動作確認観点
- [ ]
```

ルール:
- 既存の `Scene` 型を破壊する変更は避け、必要なら型を拡張する形で提案する。
- 1 タスクは「ファイル名 + 何を変えるか」が一行で伝わる粒度にする。
- 末尾に「次に Copilot に渡すならこのタスクから始めるとよい」と理由付きで 1 つ推奨する。
