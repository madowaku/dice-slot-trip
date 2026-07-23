# T011 — First v0.6 Runtime Integration

## Decision

既存Cairo本編を未完成なv0.6で直ちに置換しない。ステージ選択に「v0.6 新ルール試遊（保存なし）」を追加し、実アプリから到達できるrelease-safeな縦切りにする。新規session / atlas view / play screenへ隔離し、dirty `main.gd` はpreload、QA entry、CTA、screen生成の4箇所だけ変更する。

## Architecture

- `v06_play_session.gd`: V06RollSetとV06CourseModelを合成。position、pending route choice、1投1face、3枠、resolution、boss terminalをメモリ内所有。GameState/SaveManager/legacy BoardModelへ書かない。
- 移動完了後にfaceをslotへcommit。CHOICE_REQUIREDは未消費歩数とfaceを保持し、選択後に同じ投射を再開して一度だけcommit。
- `v06_atlas_view.gd`: canonical 44-node graphを描画。main teal solid、bypass rust dashed、loop ring + gold exit。cat中心で現在地と先10マスを主表示し、1マスhopと0.10〜0.25秒のsoft follow。
- `V06PlayScreen.tscn` / `v06_play_screen.gd`: 簡略HUD、central atlas、fixed tray、3 slots、one die、route overlay、result acknowledgement。
- `main.gd`: V06PlayScreen preload、`DICE_QA_SCREEN=v06`、stage CTA、`show_v06_game`だけ追加。legacy Cairo/character/save continuationは保持。

## Playable Acceptance

1. Title → Start → Stage Select → `v0.6 新ルール試遊（保存なし）`。
2. HUDはLAP 1、HP 3/3、PB --、1/32。mapはcatと先10マス。trayは`[_][_][_]`と1 READY die。
3. tapでroll開始、再tapまたは短いauto-stopで1〜6確定。dieは一つだけ。
4. face分catがpathを1マスずつhopし、camera follow。着地後にslotを左からcommit。tile kindは表示のみ。
5. main:12の分岐では未消費歩数を保持してmain/bypass選択後に同じ投射を続行。
6. main:22 exact landingで8-space loop。EXIT必要値を表示し、loop:4 exact landingだけmain:23へ戻る。
7. 3投目は移動後にNONE/PAIR/TRIPLE。acknowledgeまでは4投目禁止し、ackでreset。
8. main:31でboss gate terminal banner。combatは次slice。

## Scope Boundary

Deferred: boss combat/resolution、next lap、save v11、legacy migration、tile effects/rewards、final cat/atlas art、complete animation/audio、real PB、HP changes、lap result、character selection connection。

The selected PNG is a composition target, not a shipping bitmap. All text/routes are runtime-rendered with existing theme and Noto Sans JP.
