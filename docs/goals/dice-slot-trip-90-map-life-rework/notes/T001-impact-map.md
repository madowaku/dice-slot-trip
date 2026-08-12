# T001: 新90マップ・HP/LIFE影響範囲監査

Task: `T001`<br>
Kind: `scout`<br>
Status: `current`

## Summary

現行V06は58マス定義をコースJSONだけでなく、course model固定配列、atlas座標、play sessionのEVENT対応、save validation、多数のテストへ重複保持している。旧save schema 1にはコース版識別子がなく、単純復元すると旧位置を新90マスの別地点として誤認するため、新90マップとschema境界・START移行を最初のWorkerで原子的に実装する必要がある。

## Route Findings

- 分岐32→本線41は、通常9歩、4枝タイル+合流1歩=5歩、4歩短縮でwalker算術に適合する。
- 分岐71→本線83は、通常12歩、5枝タイル+合流1歩=6歩、6歩短縮でwalker算術に適合する。
- 近道1は既存3タイルから`RISK/REST/RISK/REST`の4タイルへ増やす。
- 近道2は`RISK/REST/RISK/REST/RISK`の5タイルを維持できる。
- ワープ入口24/47/66/73/83と既存のstyle/entry順は維持可能。
- tombのexact EXITはgate個別return_indexではなく共通primary/alternate復帰先で上書きされるため、Judgeが復帰先を固定する必要がある。

## Survival and Save Findings

- HP0判定はlanding後のstable-boundary正規化に集中しており、LIFE復活はここへ加えると既存EVENT/役解決順序を保てる。
- 緊急復帰はsession API、stage flag、RUN_OVER UI、低HP説明、coin testsにまたがる。
- 新規LIFE欠落セーブは3、旧max_hpとhp>3は3へ正規化する。
- save managerは現在validate後の正規化dataではなくparsed原文を返すため、migration結果をload_resultへ渡す修正が必要。
- 旧58マスschema 1は位置、coin、item、skill gauge、missions、周回内flagsをリセットし、total SCORE、BEST、LAP、説明・発見情報を一度だけ維持する。

## UI Findings

- LIFE HUDは既存`explorer-cat-idle-strip.png`先頭フレーム+`復活 ×3`が初見理解で優位。
- `あと ×3`は短いが、何の残数か分かりにくい。
- HUD第2行へ小型LIFEセルを追加可能だが3解像度の実描画が必須。
- EVENT有料CTAは不足時disabled、無料CTAは別に存在しており進行不能にはならない。ただし大きな必要コイン表示が未実装。
- スキル本体は実装済み。UIは1行6ボタンのため、2×3配置、`次の出目を選ぶ`、指定結果表示、初回READY発見フラグが必要。

## Recommended First Worker Slice

新90マップの論理トポロジーと、旧schema 1/58マスcheckpointをSTARTへ安全移行するschema 2境界を原子的に実装する。併せてHP max=3、LIFE保存/初期化のDTO骨格を入れ、旧位置を新位置として誤復元できない状態にする。HUD、復活演出、roulette、skill/event視覚改修は後続へ分離する。

## Ambiguities for Judge

- 5つのwarp return_indexとtomb共通primary/alternate exact EXIT復帰先。
- 10周ボーナスはlap 10を完了してnext_lapへ進む瞬間に付与する解釈を推奨。
- 旧HP0 checkpointはHP1へクランプする保守案を推奨。
- 旧勝利roulette未停止saveはHP3ならpendingを消してPERFECT、HP1/2なら新回復roulette pendingへ変換する必要がある。

## Evidence

- `data/stages/v06_cairo_course.json`
- `scripts/game/v06_course_model.gd`
- `scripts/game/v06_atlas_view.gd`
- `scripts/game/v06_play_session.gd`
- `scripts/game/v06_session_save_data.gd`
- `scripts/game/v06_session_save_manager.gd`
- `scripts/app/v06_play_screen.gd`
- `scenes/app/V06PlayScreen.tscn`
- `tests/run_v06_course_model_tests.gd`
- `tests/run_v06_loop_rescue_tests.gd`
- `tests/run_v06_play_session_tests.gd`
- `tests/run_v06_save_tests.gd`
- `tests/run_v06_tile_effect_tests.gd`
- `tests/run_v06_coin_economy_tests.gd`
- `tests/run_v06_boss_play_screen_tests.gd`

## Board Receipt Snippet

```yaml
receipt:
  result: done
  note: notes/T001-impact-map.md
  summary: "Mapped route/save/survival/UI ownership; fork proposals are valid, but 90-map and schema migration must be atomic."
```
