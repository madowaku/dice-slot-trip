# カイロ旅のポストカード v1

## 用途

DICE SLOT TRIP のカイロステージをクリアしたあとに表示・収集する、旅の思い出用ポストカード。

## 生成方法

通常の画像生成（参照画像3枚を使用）。

## 最終プロンプト

```text
Use case: illustration-story
Asset type: collectible stage-clear travel postcard illustration for the mobile board game DICE SLOT TRIP
Primary request: Create one polished landscape Cairo travel-memory illustration that feels like the reward for completing the whole stage. Show the established orange explorer cat and the established friendly sleeping-cat Sphinx together at sunset after the adventure. The Sphinx warmly presents a small glowing turquoise-and-gold scarab seal to the explorer cat as recognition; the explorer cat receives it proudly and happily. This is a gentle congratulations, not a battle.
Input images: Image 1 is the exact explorer-cat character and daytime Cairo detail reference; Image 2 is the exact friendly stone cat Sphinx boss and night-temple style reference; Image 3 is the Cairo/Nile color, sailboat, pyramids, and adventurous picture-book style reference. Preserve both character designs closely.
Scene/backdrop: A sweeping golden-hour Cairo panorama combining the Nile, one small felucca sailboat, a lively but distant bazaar shoreline, palms, and pyramids. Include subtle visual memories of the journey without clutter: two small gold coins near the cat's travel bag and a six-sided travel die resting on the stone foreground. The open temple gate glows softly in the distance.
Style/medium: premium hand-painted 3D storybook game illustration, warm tactile fabric, carved stone, worn brass, soft fur, consistent with the references.
Composition/framing: landscape 3:2 postcard composition. Explorer cat on the left foreground, friendly Sphinx on the right foreground, scarab seal at the shared focal point, panorama visible between and behind them. Keep all important elements comfortably inside the frame. Leave a clean band of open sunset sky across the upper-left/upper-center for later game-side title overlay.
Lighting/mood: celebratory golden sunset, calm after a long journey, affectionate and adventurous, soft teal highlights and sparkling gold dust, no dramatic danger.
Color palette: Egyptian sandstone gold, warm orange, Nile turquoise and teal, deep blue-green accents.
Constraints: Explorer cat must keep the pith helmet with round turquoise lens, teal scarf, tan expedition outfit, leather backpack, orange tabby fur, large teal-blue eyes. Sphinx must remain a large adorable rounded stone cat with striped teal-and-gold nemes headdress and forehead medallion, never humanoid. Exactly one scarab seal being presented. No additional characters. No letters, words, logos, UI, card border, stamp, watermark, or caption.
Avoid: photorealism, anime, flat vector art, aggressive monster expression, combat pose, human Sphinx face, duplicate limbs, extra dice, giant foreground objects, cluttered souvenir collage, text.
```

## 実装メモ

- 画像内に文字やUIは入れていない。
- 左上から中央上部の空が、ステージ名やクリア表示を重ねる安全領域。
- 原画は3:2（1536×1024）、実装用は1200×800。
