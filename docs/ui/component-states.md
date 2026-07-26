# モバイルUI コンポーネント状態

UI-P0Bでは、Godot標準Themeへの偶発的な依存をなくすため、ボタンの見た目を
`res://assets/ui/theme_mobile.tres`へ集約する。

## Button Type Variation

| Variation | 用途 | 使い分け |
|---|---|---|
| `PrimaryButton` | 画面の主目的 | 1画面につき原則1個 |
| `SecondaryButton` | 戻る、設定、補助操作 | 押せる選択肢の標準 |
| `SelectedButton` | 選択済みカード | 無効状態と混同させない |
| `DangerButton` | 破棄などの危険操作 | 確認が必要な操作だけ |
| `CompactButton` | 密度の高い補助操作 | 文字はCaption、タップ高は96以上 |

各Variationは `normal`、`hover`、`pressed`、`hover_pressed`、`focus`、
`disabled` を明示する。`Button`本体にもSecondary相当の完全な状態を定義し、
Variationの指定漏れがGodot標準表示へ落ちないようにする。

## 状態の意味

- 未選択は `SecondaryButton`。押せることが分かる明るい紙面を使う。
- 選択中だけ `SelectedButton`。太いteal境界とチェックで二重に示す。
- `disabled` は未解禁、入力待ち、遷移中など、本当に操作できない場合だけ使う。
- `pressed` は面を暗くして影を縮め、指への即時反応を示す。
- `focus` は基底面を隠さない金色の外周にし、キーボード／コントローラー操作を保つ。

## 旅人選択

旅人カードのタップは仮選択であり、ゲーム状態やセーブを変更しない。

```text
カードをタップ
→ Selected状態を1枚だけ表示
→ 能力説明を更新
→ 「この旅人で出発」を有効化
→ CTAで新しい旅を初期化・旅人を確定・保存・ゲームへ遷移
```

CTA確定時は先に遷移ロックを立て、CTAと全カードを無効化する。連打や
ダブルタップで新規ゲーム初期化が二重実行されないことを受け入れ条件とする。
