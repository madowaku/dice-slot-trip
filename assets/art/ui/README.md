# 共通UIキット

カイロ専用画面に閉じず、全ステージで使うダイス・スロット装置の共通素材です。文字、数字、状態判定はGodot側で描画し、画像は材質・縁・光だけを担当します。

## 実装用ファイル

| ファイル | 用途 |
| --- | --- |
| `common/dice-ivory-brass.png` | ロールボタンとミッションで使うアンティークダイス。通常マップの回転表示はシンプルな3Dダイスを使う。 |
| `common/slot-tray-3.png` | 3つのダイスが入る共通トレー。浅いくぼみ、真鍮の枠、リベット付き。横長のTextureRectとして配置。 |
| `common/roll-button-ornaments.png` | ロールボタンの装飾アトラス。中央は透明で、文字とティール色の本体はGodot側。 |
| `common/slot-snap-sparkle.png` | ダイスがスロットへ吸着した瞬間の短い光・火花。透明背景。 |
| `common/map-panel-frame-v1.png` | 全体マップ overlay の透明センター付き真鍮・青緑フレーム。MapPanel の外周装飾として重ねる。 |
| `common/skill-pinpoint-v1.png` | ピンポイントスキルの共通アイコン。真鍮コンパス針と象牙ダイスを描いた透明アイコン。 |

## ロールボタンのアトラス順

`roll-button-ornaments.png` は 941×1672px、1セル941×418pxの縦4段です。

1. 通常 — 磨いた真鍮の縁と小さなティールの反射
2. 押下 — 暗い真鍮と内側へ沈む光
3. 使用不可 — 彩度を落とした真鍮
4. 完成発光 — 金色の発光と小さな火花

実装では `scripts/app/v06_play_screen.gd` の `AtlasTexture` がセルを切り替えます。ボタンの文章・フォント・判定は画像へ焼き込みません。

## 参照ルール

- 直接参照する画像は `assets/art/ui/` 以下に置く。
- 生成元のクロマキー画像は `assets/art/_source/ui-kit/` に保管し、実行時には参照しない。
- `map-panel-frame-v1` と `skill-pinpoint-v1` の生成元は `assets/art/_source/ui-kit/` に保管する。
- 状態を増やす場合は、アトラスのセル順を更新してこのREADMEとコードの対応を同時に変更する。
- 色の基準は `#F0E0BF` 前後の象牙、`#173B3B` 前後の濃い青緑、`#B88A46` 前後の古びた真鍮。
