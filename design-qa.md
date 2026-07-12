# Premium UI Design QA

基準画像: `ステージ画面イメージ.png`
実装証跡: `docs/reference/runtime-premium-ui-one.png`、`two.png`、`three.png`、`risk.png`、`rolling.png`

## 比較結果

| 観点 | 参考画像の意図 | 現在の実装 | 判定 |
|---|---|---|---|
| 情報階層 | 周回・コイン、ボス、全体マップ、盤面、ダイスの順 | lap/coin pill、ボスカード、独立minimap、大型盤面リボン、革trayへ分離 | Passed |
| 現在地 | キャラクターと前後マスを大きく見せる | 現在±5の11マスを番号・色・記号付き連続タイルで表示 | Passed |
| 全体位置 | 90マスループを常時確認 | ボスカード横の独立カードに全90マスと現在地を維持 | Passed |
| ボス交流 | 肖像・名前・実ゲージを一枚のカードに統合 | parchment card、portrait、ProgressBar、交流率・気配・スタンプ | Passed |
| ダイス状態 | 出目、役、次の操作を一目で理解 | 立体ダイス、role、NORMAL / DOUBLE CHANCE / DICE SLOT indicator、主CTA | Passed |
| リスク | 目押し前に危険マスを予告 | 赤い`!`、番号、NEXT表示、現在地の`!`を大型リボンで表示 | Passed |
| モバイル到達性 | 主操作を下部へ固定 | roll、左停止、一括停止を革tray下端へ配置 | Passed |

## 修正監査

- P0 fixed: 状態名が狭い領域で縦組みになっていた。固定幅・折返しなしへ変更。
- P0 fixed: 旧モード選択Buttonを廃止し、操作不能な3段階progress indicatorへ変更。
- P1 fixed: 点線ルートの単純拡大を、大型連続タイルリボンへ変更。
- P1 fixed: ボス情報をテキスト一行から肖像・名前・実ProgressBar付きカードへ変更。
- P1 fixed: 暗い仮設trayと強い黄橙planeを、丸い砂革panel・淡い革plane・金縁へ変更。
- P1 fixed: 3Dダイスを約1.24倍、1ダイス時約1.48倍へ拡大。プレイヤーも拡大。
- P2 fixed: 背景artの不透明度を上げ、文字は不透明度の高いpanel上へ集約。
- P2 fixed: Compatibility rendererの静止2ダイス証跡は安定capture経路で再取得。

## 360 × 640 判定

- one / two / three / risk / rolling の全証跡で、ボスカード、minimap、盤面、tray、主CTA、ターン情報が画面内。
- rolling時も「左から止める」と「残りを一括停止」が同じ横列にあり到達可能。
- boss/event/risk modalは既存CanvasLayerを維持し、盤面・ダイス入力を遮断する。

## 残課題（P3）

- 参考画像の立体的な石畳パースや個別アイテムアイコンは、専用アート制作を伴う後続polish候補。
- 小型画面では図鑑・ショップ常設ショートカットを盤面へ追加する余白がないため、情報過密を避けて未配置。
- 3Dダイスの角丸・革tray固有テクスチャは、現在のBoxMesh／単色材質から将来差し替え可能。

結論: P0〜P2を解消し、M3/M4A/RISK/早止めを保ったGoogle Play有料級の第一UIスライスとしてPassed。
