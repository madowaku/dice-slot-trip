# UI-P0D Screen Audit

監査日: 2026-07-17

## Capture matrix

Release policyを模擬し、Tourism固定・DEBUG非生成の状態で以下を実寸キャプチャした。

| 幅・高さ | タイトル | 旅先 | 旅人選択済み | 初回ロール |
|---|---|---|---|---|
| 360 × 640 | PASS | PASS | PASS | PASS |
| 393 × 852 | PASS | PASS | PASS | PASS |
| 412 × 915 | PASS | PASS | PASS | PASS |

追加確認:

- 砂嵐のキャラバン道: 360 × 640 PASS
- 王の迷い環: 360 × 640 PASS
- 旅先カードの長い名称: 14px相当、欠けなし
- Cairoカードの2行caption: 393／412のfractional scaleで欠けなし
- 旅人選択: 未選択、選択、Disabled CTAを明確に判別可能
- Release相当ゲームHUD: DEBUGなし、Tourism、CTAまで画面内
- キャプチャ: GPU readback後の黒抜けを検知して再試行

## 目視項目

- 最初の視線は画面タイトルまたはPrimary CTAへ向かう。
- 押せるカードは明るい紙面、選択中はteal太枠とチェックで示す。
- Disabledは旅人未選択CTAと未解禁コンテンツだけに使う。
- 本文16px相当、補助文と旅先カード14px相当を維持する。
- 主要CTAは実タップ高52px相当、最低タップ領域48px相当を維持する。
- 360幅でも本文、CTA、HUD、ステータス行が欠けない。

## 実機でのみ完了できる項目

以下はPCキャプチャでは判定せず、Android実機の受け入れ項目として残す。

- ノッチ、パンチホール、ジェスチャーナビ領域
- 指で隠れる操作と押しやすさ
- 片手操作時の到達性
- OSの文字レンダリングと端末DPI
- 画面回転、復帰、アプリ中断後のレイアウト

