# Release UI Policy

製品版で開発設備へ到達できないことを、表示とロジックの両方で保証する。
実装の判定元は `res://scripts/ui/release_policy.gd` とする。

## Release build

- ボード表示は常にTourism。
- 保存済みのClassic設定と `DICE_BOARD_VIEW=classic` を採用しない。
- DEBUGトグルとdebug panelを生成しない。
- Classic/Tourism切替操作を受け付けない。
- `DICE_DEBUG_ROUTE`、`DICE_DEBUG_FLOW`、`DICE_DEBUG_DICE_COUNT` を無視する。
- 保存済みClassic値は削除・上書きしない。将来のDebug buildで再利用できる。

## Debug build

- 保存済みClassic/Tourism設定を採用する。
- `DICE_BOARD_VIEW` の明示指定を優先する。
- DEBUGパネルとClassic/Tourism切替を利用できる。
- 切替結果は従来どおり保存する。

## 受け入れ条件

- `preferred_board_view_mode("classic", false, "classic")` はTourismを返す。
- Release policyはClassic切替要求を拒否する。
- Debug policyは保存値と明示overrideを維持する。
- Releaseでポリシーを評価しても、GameState内の保存値は変更しない。
- Debug buildの既存QAではClassicとTourismを両方生成できる。
