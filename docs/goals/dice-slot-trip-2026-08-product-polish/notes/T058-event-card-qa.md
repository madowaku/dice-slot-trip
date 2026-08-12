# T058 EVENTカード視覚QA

## 結果

pass。T055/T057の4つのV06-native EVENTカードは、実OpenGL描画で画像・タイトル・本文・条件付き発見スコア・CTAが一致し、対象3 viewportでカード自体にclip・ellipsis・overlap・crop・stretchはなかった。

## 実描画

- `build/qa-event-market-720x1280.png`
- `build/qa-event-nile-720x1280.png`
- `build/qa-event-ruin-720x1280.png`
- `build/qa-event-ferry-720x1280.png`
- `build/qa-event-ferry-360x640.png`
- `build/qa-event-ferry-720x1600.png`
- `build/qa-event-ferry-repeat-no-score-720x1280.png`
- `build/qa-event-four-card-contact-720x1280.png`
- `build/qa-event-reference-comparison-1440x1280.png`
- `build/qa-event-ferry-responsive-comparison-1440x1280.png`

## 幾何

- 720×1280、3行本文の市場／ナイル／遺跡: card `(50,321) 620×637`。
- 720×1280、2行本文の渡し船: card `(50,340) 620×599`。
- 360×640: 720×1280 design viewportを0.5倍表示し、渡し船CTAは96 design px / 48 physical px。
- 720×1600: 渡し船card `(50,500) 620×599`。縦伸びせず中央へ移動する。
- art slotは570×330、sourceは1024×768。`STRETCH_KEEP_ASPECT_CENTERED`で4:3比を保持し、crop/stretchなし。
- dim overlayは全viewportを覆い、dismiss前後のPage/HUD/Tray/Dock rectは一致した。

## 操作・時計

- 背景tap、戻る、ダイス、MAP、MENU、ITEM、SKILLはいずれもcardを閉じず下層を発火しない。
- CTAだけが一度閉じ、rollへ漏れない。
- card表示中のelapsedは不変で、owned pauseだけを閉じる時に戻す。
- repeat + `score_awarded=false` の実描画では `発見スコア +150` を表示しない。

## デザイン監査

4枚はそれぞれ市場、帆走、遺跡、渡し船のliteral artとcopyが一致する。選択済み豪華版モックとの横並びでは、既存のアイボリー、金縁、ターコイズ見出しを保ち、下層を暗くして物語カードへ視線を集める。新規ImageGenは不要で、既存1024×768資産の方が内容・画風・寸法とも適合した。

既存の720×1280基礎Pageは上下へ39pxはみ出すが、EVENT cardは完全にviewport内で、720×1600ではPage全体も内側に収まる。これは既知の16:9基礎Page課題で本スライスをblockしない。
