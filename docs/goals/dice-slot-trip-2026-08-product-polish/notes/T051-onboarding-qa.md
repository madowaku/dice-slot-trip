# T051 — 初回3投オンボーディング QA

## 結果

オンボーディング固有の自動・入力・保存・視覚契約は pass。

- 既存 `LandingArtOverlay` と `slot-tray-luxury-v1.png` を使用。
- 背景、戻る、ダイス、マップ、アイテム、スキルは表示中に作動しない。
- CTA 一回だけで閉じ、ロールへ入力が漏れない。
- fresh start の時計は 0 ms のまま。
- dismiss 前後で Page / HUD / Tray / ToolDock の rect は完全一致。
- JA copy、タイトル、本文、CTA は各 authored row 内に収まり、省略・重なりなし。

## 自動回帰

- Godot 4.7 headless editor parse: pass
- `tests/run_v06_play_screen_tests.gd`: failures=0
- `tests/run_v06_save_tests.gd`: failures=0
- `tests/run_v06_tile_help_tests.gd`: failures=0
- `tests/run_v06_travel_menu_tests.gd`: failures=0
- `tests/run_v06_boss_play_screen_tests.gd`: failures=0
- `tests/run_tests.gd`: failures=0
- scoped `git diff --check`: pass
- Goal Maker state checker: pass

## 実 OpenGL capture

| Window | Logical viewport | Card rect | CTA | 結果 |
|---|---:|---:|---:|---|
| 360×640 | 720×1280 | `(50,321) 620×637` | 96 design / 48 physical px | pass |
| 720×1280 | 720×1280 | `(50,321) 620×637` | 96 px | pass |
| 720×1600 | 720×1600 | `(50,481) 620×637` | 96 px | pass |

720×1600 ではカード寸法と画像比率を変えず、上下の余白だけが各 160 design px 増える。dim は全 viewport を覆う。

Evidence:

- `build/qa-onboarding-360x640-card.png`
- `build/qa-onboarding-360x640-dismissed.png`
- `build/qa-onboarding-720x1280-card.png`
- `build/qa-onboarding-720x1280-dismissed.png`
- `build/qa-onboarding-720x1600-card.png`
- `build/qa-onboarding-720x1600-dismissed.png`
- `build/qa-onboarding-reference-comparison-1440x1280.png`
- `build/qa-onboarding-360x640.avi` (Movie Writer は project override により 360×800)

## Visual review

選択済み豪華版モックと 720×1280 capture を同じ比較画像で監査。金・ターコイズ・アイボリーの装飾、三窓トレイ、羊皮紙面が既存画面と一致し、初回説明で主操作の視覚語彙を先に学べる。360×640 でも本文は読め、CTA は物理 48 px を維持する。

## Capture caveat / deferred finding

- CLI Movie Writer は現在の `window_width_override=360` / `window_height_override=800` を使用したため、`--resolution 360x640` 指定でも 360×800 を記録した。最終静止画は実 OpenGL root viewport を一時的に枠なし指定サイズへ変更して取得し、PNG 自体の寸法を確認した。
- headless viewport readback は既知経路で一度 timeout。stop_if に従い再試行せず、OpenGL capture を正とした。
- 16:9 capture では基礎 Page の authored minimum height が viewport より大きく、HUD 上端と ToolDock 下端が一部 viewport 外になる。オンボーディング card 自体は全辺内で、dismiss 前後も pixel-stable。ユーザーが報告した縦長端末 720×1600 では Page 全体が `(16,16) 688×1568` に収まるため、今回の onboarding slice を block しない。16:9 を正式対応範囲に含める場合は別 Scout で扱う。
