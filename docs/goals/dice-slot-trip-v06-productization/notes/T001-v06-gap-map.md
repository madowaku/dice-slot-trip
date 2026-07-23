# T001 — v0.6 現行差分マップ

## Summary

現行は Godot 4.7 / 720 x 1280、保存トランザクション、観光マップ、2.5Dダイス、分岐、8マス円環の再利用資産が強い。一方、ゲーム核は旧90マス・同時1/2/3/5ダイス・毎投役判定・偶発ボス交流で、v0.6の30〜36マス・毎投1個・3投蓄積スロット・周回末HPボスとは全面的に衝突する。既存テストは緑だが旧仕様を強く固定している。

## Repo / Runtime Map

- 入口: `project.godot:14-40`。`Main.tscn`、GameState / SaveManager、720 x 1280 portrait、GL compatibility、ETC2 / ASTC。
- 状態と復帰: `autoload/game_state.gd:79-85` は1〜3個と一時5個、`251-335` はroll transaction、`571-645` と `740-830` はv10保存・移行。`autoload/save_manager.gd:3-35` はJSON保存。
- 盤面: `scripts/game/board_model.gd:4-18` は90マス、`40-62` は本線90・バイパス10・正確停止円環8、`75-120` は経路移動。`data/stages/cairo_hourglass.json:5` も90マス。
- 実行UI: `scripts/app/main.gd:926-1030` は観光盤面・固定下部トレイ・現在ダイス数、`1215` と `1297-1474` は停止・役・移動・保存、`2353` は周回・ターン・次回ダイスHUD。
- ダイス: `scripts/game/map_dice_overlay.gd:312-373` は1/2/3/5同時formation、`398-415` は個別停止、`535-584` は3個同時slot frame。3投蓄積ではない。
- 描画: `scripts/game/board_view.gd:63-92,364-393` と `scripts/game/tourism_map_view.gd:369-424`。token hopはあるが独立した遅延Camera2Dはなく、近傍道路の再描画方式。
- 素材: Noto Sans JP、Kenney CC0小物、ImageGen背景・人間旅人・スフィンクス、ダイス/UI SE、prompt/attributionがある。初期ネコと承認済みanimation stripはない。

## v0.6 Gap Matrix

| Area | Status | Gap |
|---|---|---|
| Game code | Major | 30〜36周回、1投1個、3投保存後だけPAIR/TRIPLE、player/boss HP3、周回末ボス、自己ベスト/目押し率がない。 |
| Reusable code | Partial | 8マスexact-stop円環、分岐、durable transaction、pause saveは移行可能。旧dice_countと90基準を切り離す必要がある。 |
| UI | Major | 固定トレイと中央マップはあるが、3投履歴、player HP、自己ベスト差、周回末boss HP、30〜36進行がない。 |
| Movement/camera | Major | hop offsetはあるが、キャラのworld移動＋遅延Camera2D＋進行方向offsetではない。 |
| Assets | Partial | カイロ背景・ボス・小物・音は再利用可。ネコ基準フレーム、共通anchor animation、3 visual targets、正式app iconがない。 |
| Android | External evidence missing | safe-area自動テストとpresetはある。実機、正式icon、release keystore、性能、振動、音mixの証拠がない。 |

## Verification / Current Health

- Godot 4.7 version: pass — `4.7.stable.official.5b4e0cb0f`。
- `Godot 4.7 --headless --path . --editor --quit`: pass。
- `Godot 4.7 --headless --path . --script tests/run_tests.gd`: pass with exit warnings — `DICE_SLOT_TRIP_TESTS failures=0`、終了時に5 ObjectDB leakと1 resource still in use。
- `Godot 4.7 --headless --path . --script tests/run_roll_transaction_tests.gd`: pass — `ROLL_TRANSACTION_TESTS failures=0`。
- `git diff --check`: whitespace errorなし、6 tracked filesにLF→CRLF warning。
- 現行ロジック回帰は緑だが、v0.6 acceptance testはゼロ。旧90マス・複数ダイスのpassはv0.6適合証拠ではない。

## Ranked Safe Candidates

1. `docs/design/v06/**` だけを使い、同一ゲーム状態のvisual targetを3案作る。dirty実装と無重複で、実装前選定ルールを満たす。
2. 新規 `scripts/game/v06_roll_set.gd` と専用テストで、1値を3枠へ蓄積し、3投目後だけPAIR/TRIPLE判定・resetする純粋ドメインモデルを作る。既存 `main.gd` と旧テストを触らない。
3. 新規 stage JSON、course model、専用テストで30〜36本線、バイパス1、8マスexact-stop円環、boss gateを旧90モデルと並行定義する。マス数定義をJudgeが決めてから行う。

`main.gd` / GameState / board views / save v11 / 製品UI / HP統合はvisual選定とmigration判断後まで延期する。

## Visual Inputs / Missing Evidence

Inputs:

- `docs/reference/android-ui-game-tourism.png`
- `docs/reference/runtime-premium-ui-one.png`
- `docs/reference/runtime-tourmap-classic.png`
- `docs/reference/game_concept.png`
- `docs/reference/title_concept.png`
- `docs/reference/stage_select_concept.png`
- `assets/art/backgrounds/cairo-board.png`
- `assets/art/bosses/sleepy-sphinx.png`
- `assets/art/map_props/**`
- `assets/audio/dice/**`

Missing:

- 同じv0.6ゲーム状態を示す720 x 1280製品画面3案と所有者選定。
- ネコの承認済み基準フレーム、全strip、anchor仕様。
- 3投slot、HP、自己ベスト差、30〜36周回、円環EXIT必要値を同時表示したruntime capture。
- Android 360 / 393 / 412実機capture、frame/performance、haptics、speaker/headphone mix。
- 正式app icon、release署名、Play向けbuild/install証拠。

## Dirty Worktree Risk

- tracked差分は `project.godot`、`scripts/app/main.gd`、`scripts/game/board_view.gd`、`scripts/game/dice_presentation_3d.gd`、`scripts/game/tourism_map_view.gd`、`tests/run_tests.gd`。819 insertions / 258 deletions。
- v0.6統合候補の大半と重なる。特に `main.gd`、board/tourism view、`tests/run_tests.gd` は高衝突。
- `assets/ui`、`scripts/ui`、`title-hero`、Android UI captures、`docs/ui`、`export_presets.cfg` もuntracked。所有権を確認せず上書きしない。
- Scout調査後もtracked source fingerprintは不変。

## Judge Ambiguities

- 旧90マス体験をdebug/legacyとして残すか、v0.6へ完全置換するか。
- 30〜36の確定本線マス数と、8マス円環・バイパスを本線数へ含めるか。
- v10旧saveを新ランへ移行、アーカイブ、互換打切りのどれにするか。
- dirty `main.gd` の大差分へ統合作業を重ねてよいか。
