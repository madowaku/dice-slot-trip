# マス種別アイコン選定・出典記録

## 結論

T029で確定した外形、色、優先順位を変えず、中央の意味記号だけを Kenney Board Game Icons の白マスクへ置換する。対応は `NORMAL=arrow_right`、`COIN=tokens_stack`、`REST=campfire`、`RISK=skull`、`ITEM=pouch`、`EVENT=book_open`。START、分岐、ループ、EXIT、ボス門など構造マスの記号は変更しない。

## 候補比較（各種2〜3案）

| 種別 | 候補 | パック | 判断 |
|---|---|---|---|
| NORMAL | `arrow_right.png` / `pawn_up.png` | Board Game Icons | 直進を即読できる arrow_right |
| NORMAL | `PNG/Default (128px)/tiles.png` | Board Game Info | 盤面一般を示すため不採用 |
| COIN | `tokens_stack.png` / `token.png` | Board Game Icons | 複数報酬が読める tokens_stack |
| COIN | `PNG/Chips/chipWhite_border.png` | Boardgame Pack | 写実寄りのチップのため不採用 |
| REST | `campfire.png` / `suit_hearts.png` | Board Game Icons | 休息地点を表す campfire |
| REST | `PNG/Default (128px)/hourglass.png` | Board Game Info | 時間情報に見えるため不採用 |
| RISK | `skull.png` / `sword.png` / `exploding.png` | Board Game Icons | 小サイズで輪郭が最も単純な skull |
| ITEM | `pouch.png` / `hand_cube.png` / `cards_collection.png` | Board Game Icons | 携行品として即読できる pouch |
| EVENT | `book_open.png` / `dice_question.png` | Board Game Icons | 出来事・物語を示す book_open |
| EVENT | `PNG/Default (128px)/interaction.png` | Board Game Info | 人数・交流情報に見えるため不採用 |

## 正規化仕様

- 変更前の原本は `third_party/kenney-board-game-icons/selected-originals/` に保存する。
- `tools/normalize_kenney_tile_icons.py` がアルファ境界でクロップし、縦横比を維持して128×128透明キャンバスへ配置する。
- 光学ボックスは共通100〜108px帯（arrow/skull 102、tokens/campfire/pouch 104、book 106）。重心補正は縦0〜1pxのみ。
- 線密度を揃えるため全種へ同一の1pxアルファ膨張を行う。任意変形や個別ストレッチは行わない。

## ライセンス・再現性

3パックはいずれも Kenney の CC0 1.0。各 `source_url.txt` に公式配布元と取得アーカイブSHA-256、各 `LICENSE.txt` に同梱ライセンスを保存した。Preview、logo、sample は保存していない。本番PNGはスクリプトで再生成できる。
