# T004: ボスカメラ・効果座標 Visual QA

Task: `T004`
Kind: `pm`
Status: `current`

## Summary

Godot 4.7 OpenGL Movie Writer で既存のボスレース全体 harness と、着地セル pictogram を表示した focused harness を記録した。focused sequence を 25 fps の contact sheet に分解すると、camera は静止区間から一つの連続した単調移動へ入り、その後静止しており、旧録画にあった 2 マスごとの再始動は見られない。pictogram は camera 前・途中・後で同じ landing cell と一緒に移動し、独立した画面座標へ取り残されない。

## Evidence

- `build/qa-boss-camera-360x640.avi`: 360×640、30 fps、1109 frames、36.97 秒の full race。
- `build/qa-boss-camera-anchor-360x640.avi`: 360×640、30 fps、133 frames、4.43 秒の focused camera / anchor sequence。
- `build/qa-boss-camera-anchor-tween-contact.png`: camera 開始前後 1 秒を 25 frames に分解。静止 → 一つの連続移動 → 静止。
- `build/qa-boss-camera-anchor-before-720x1280.png`
- `build/qa-boss-camera-anchor-mid-720x1280.png`
- `build/qa-boss-camera-anchor-after-720x1280.png`
- `build/qa-boss-camera-new-contact.png`: 修正後 full race の連続状態。
- `build/qa-boss-camera-original-contact.png`: ユーザー録画の比較用連続状態。

## Checks

- full race と focused movie は Godot 4.7 OpenGL で完走。
- focused contact sheet は途中の逆走、停止、再加速、target 切替を示さない。
- `tests/run_v06_boss_play_screen_tests.gd` は camera target の一回決定、600〜1000ms の単一 settle、pictogram の `lane_point(anchor) + authored offset` 一致を camera 前後で検証済み。
- 720×1280 展開画像で HUD、盤面、トークン、ROLL tray が画面内に収まり、pictogram / token / tile の相対関係が 360×640 と一致する。

## Caveat

既存の headless `SubViewportTexture.get_image()` 経路は 720×1280 static capture で 120 秒 timeout した。製品コードや test harness は変更せず、成功した実動 360×640 Movie Writer frame を Lanczos で 720×1280へ展開し、native 720 geometry は専用 headless test の `720×1280` host / rect assertions で補完した。

## Board Receipt Snippet

```yaml
receipt:
  result: done
  note: notes/T004-boss-camera-visual-qa.md
  summary: "実動動画は静止→単一連続camera移動→静止となり、pictogramはlanding cellへ追従した。"
```
