# T001: ボスカメラ・効果座標マップ

Task: `T001`
Kind: `scout`
Status: `current`

## Summary

録画の明確な反復スクロールは約 7.6〜9.6 秒にあり、現行実装が 2 マス単位の camera target を最大 10 区間まで逐次計算して Tween を作り直す契約と一致する。効果ピクトグラムは盤面・トークンと同じ `RaceStage(Control)` のローカル座標を使うが、表示開始時に一度だけ course position を投影し、その後の camera 更新で再投影されないため対象セルから離れる。

## Recording Facts

- 3.8〜4.6 秒: YOU 5 / SPHINX 2、盤面とトークンは静止。
- 4.8〜5.4 秒: STOP 中に着地候補リングが移動。盤面スクロールは見えない。
- 5.6〜6.0 秒: 出目確定、YOU 10 / SPHINX 5 へ更新。
- 6.2〜7.4 秒: プレイヤー、続いてスフィンクスが個別移動し、効果ピクトグラムが出る。
- 約 7.6〜9.6 秒: 盤面が複数の 2 マス区間に分かれて縦移動し、ピクトグラムと対象セルの相対位置が崩れる。

## Code Path

```text
_run_face
  -> _play_boss_roll_sequence
     -> base_steps loop
        -> _position_boss_tokens
           -> Tween -> _apply_boss_visual_lerp
              -> _sync_boss_board_tokens
     -> _animate_boss_landing_effects
        -> _set_target_pictogram [lane_point を一度だけ position へ投影]
        -> effect_steps loop -> _position_boss_tokens
     -> _settle_boss_camera_after_movement
        -> while segment_count < 10
           -> next_camera_scroll_target [毎回 ±2 マス]
           -> 新規 camera Tween
           -> _apply_boss_camera_position
              -> board.set_camera_position
              -> _sync_boss_board_tokens [盤面とトークンだけ再投影]
```

## Ownership And Risk

- `scripts/ui/v11_boss_lane_board.gd`、`tests/run_v06_boss_play_screen_tests.gd`、`tests/record_v10_boss_race.gd`、`scripts/game/v06_boss_battle.gd` の問題箇所は HEAD `6322e1d` と同一。
- `scripts/app/v06_play_screen.gd` は別機能の protected dirty 差分が大きい。同一ファイルへ部分パッチする必要があるため、前後 fingerprint と限定 diff が必須。
- `scenes/app/V06PlayScreen.tscn` の既存効果ノード構造は変更不要で、scope 外に置ける。
- `scripts/game/v06_boss_battle.gd` は出目と効果結果を所有し、camera / projection 修正対象ではない。

## Existing Test Conflict

`tests/run_v06_boss_play_screen_tests.gd` は 2 マス単位の反復 camera settle と 2300ms 以上の所要時間を期待しており、今回の受入条件と逆向き。camera 変更後も pictogram が対象 `lane_point` と一致する検証は存在しない。

## Evidence

- `C:/tmp/dice-slot-t001-frames/contact.png`
- `C:/tmp/dice-slot-t001-late/contact.png`
- `scripts/app/v06_play_screen.gd:683`
- `scripts/app/v06_play_screen.gd:745`
- `scripts/app/v06_play_screen.gd:1493`
- `scripts/app/v06_play_screen.gd:2097`
- `scripts/app/v06_play_screen.gd:2128`
- `scripts/ui/v11_boss_lane_board.gd:73`
- `scripts/ui/v11_boss_lane_board.gd:97`
- `tests/run_v06_boss_play_screen_tests.gd:181`
- `tests/run_v06_boss_play_screen_tests.gd:209`

## Board Receipt Snippet

```yaml
receipt:
  result: done
  note: notes/T001-boss-camera-effect-map.md
  summary: "反復2マスcamera Tweenと、camera更新時に再投影されないpictogram local positionを根因として特定した。"
```
