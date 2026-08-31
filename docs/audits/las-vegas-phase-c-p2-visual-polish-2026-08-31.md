# DICE SLOT TRIP Las Vegas Phase C P2 Visual Polish

実施日: 2026-08-31
対象: DICE RACE / DICE TOWER / DICE ROULETTE / TREASURE 21 / DICE POKER / VAULT BREAK

## 判定

Phase Cの残存P2を、既存素材と小規模なUIコード変更だけで処理した。経済、BET額、ゲームルール、CasinoBank、transaction、勝敗判定は変更していない。新規画像生成も不要だった。

| 評価 | Phase C前 | P2後 |
| --- | ---: | ---: |
| 製品UI総合 | 94 / 100 | **96 / 100** |
| 経済 / transaction | 変更なし | 変更なし |
| 360×800 visual QA | 既存27枚 | P2後の実描画を追加 |

## 変更内容

| 対象 | Before | After | 理由 |
| --- | --- | --- | --- |
| DICE TOWER RESULT | 背後のTOWER操作面とCTAが0.48 alphaのdim越しに競合 | `ResultDim`を0.68へ強化し、結果overlayとdimの入力を停止 | BUST / RETURN / NET / PLAY AGAINへ視線を固定し、背後の文脈は残す |
| VAULT BREAK RESULT | 結果カードがラベル中心で、setup/activeの金庫扉との視覚連続性が切れていた | 既存 `vault-door-brass-v1.png` を `ResultVaultDoorPanel` として再利用。成功は真鍮色、失敗は減光 | 新規素材なしで「金庫を開けた／拒否された」を一目で理解 |
| 6施設 CHIP残高 | `CHIP` / `CASINO CHIP` / `所持チップ` が施設ごとに揺れていた | 6施設の残高見出しを `CASINO CHIP` に統一（Poker / Vault / Hubは既存表記を維持） | 同じ意味のラベルを同じ名称にする |
| DICE ROULETTE 終了後CTA | `新しくBET` / `終了` | `CHANGE BET` / `カジノへ戻る` | TOWERなどと同じ操作意味を共有し、戻り先を明示 |

### DICE TOWER Before / After

| 条件 | Before | After |
| --- | --- | --- |
| 結果背景のdim | 0.48 | **0.68** |
| dim入力 | 暗黙の既定値 | `MOUSE_FILTER_STOP` |
| 結果主CTA | PLAY AGAIN | PLAY AGAIN（変更なし） |
| 結果副CTA | CHANGE BET / やめる | CHANGE BET / **カジノへ戻る** |

### CHIP / CTA横断

| 施設 | 残高見出し | 結果・再戦の主CTA |
| --- | --- | --- |
| DICE RACE | CASINO CHIP | NEW RACE（setupへ戻る） |
| DICE TOWER | CASINO CHIP | PLAY AGAIN / CHANGE BET |
| DICE ROULETTE | CASINO CHIP | 同じBETでSPIN / CHANGE BET |
| TREASURE 21 | CASINO CHIP | PLAY AGAIN |
| DICE POKER | CASINO CHIP | PLAY AGAIN |
| VAULT BREAK | CASINO CHIP | NEW VAULT |

固有行為（STOP、SPIN、HIT、DEAL、CASH OUT）はゲームの差別化のため残している。同じ「変更」「再戦」「カジノへ戻る」だけを横断的に整理した。

## 360×800 / 720×1280 実描画

P2後の実描画は以下に保存した。

- `artifacts/audit/las-vegas-phase-c-p2-after/tower/`: setup / active / BUST / success、360×800（補助360×780を含む）
- `artifacts/audit/las-vegas-phase-c-p2-after/results/vault-result-360x800.png`: 金庫扉つき結果画面
- `artifacts/audit/las-vegas-phase-c-p2-after/race-setup-ready-360x800.png`: CASINO CHIP見出しの収まり
- `artifacts/audit/las-vegas-phase-c-p2-after/expansion/`: Hub、ROULETTE、TREASURE、POKER、VAULTの360×800
- `artifacts/audit/las-vegas-phase-c-p2-after/expansion-720x1280/`: 同じ状態の720×1280

確認結果:

- TOWER結果カードは背後の操作面より明確に前面化し、主要CTAは画面内。
- VAULT結果の扉はカード幅に収まり、成功時の真鍮色と結果見出しが連続する。
- `CASINO CHIP` の2行見出しはRACE / ROULETTE / TREASURE / TOWERの狭いヘッダーでもクリップしない。
- ROULETTEは情報量が多いが、360×800でBET、SPIN、結果CTAのタップ領域を維持。固定action dockの重なりは既存設計の範囲で、P2 blockerではない。

## テスト

| Suite | Assertions | Failures |
| --- | ---: | ---: |
| Casino foundation | 36 | 0 |
| Casino models | 248 | 0 |
| Dice Roulette | 80 | 0 |
| Vault Break model | 452 | 0 |
| Casino UI | 177 | 0 |
| Casino expansion UI | 116 | 0 |
| Dice Poker | 55 | 0 |
| Treasure 21 | 91 | 0 |
| Vault Break UI | 61 | 0 |
| **Las Vegas baseline** | **1,316** | **0** |
| Phase C visual | 29 | 0 |

追加確認:

- `run_roll_transaction_tests.gd`: failures=0
- `run_tests.gd`（DICE SLOT TRIP基盤）: failures=0
- GUI recorder: 360×800と720×1280の非空PNGを生成。TOWER主要CTAとVAULT結果カードを目視確認。

## 変更ファイル

- `scripts/app/dice_tower_screen.gd`: 結果dimの階層・入力遮断、残高見出し、副CTA。
- `scripts/app/vault_break_screen.gd`: 既存金庫扉の結果カード再利用と成功／失敗の色分け。
- `scripts/app/dice_race_screen.gd`: 残高見出し統一と狭幅ヘッダー調整。
- `scripts/app/dice_roulette_screen.gd`: 残高見出しと変更／退出CTAの統一。
- `scripts/app/treasure_21_screen.gd`: 残高見出し統一。
- `tests/record_dice_race.gd`: QAキャプチャの残高見出しを本番と一致。
- `tests/run_casino_ui_tests.gd`: 6施設語彙、TOWER結果dim、ROULETTE CTAの回帰。
- `tests/run_treasure_21_tests.gd`: TREASURE残高見出しの回帰。
- `tests/run_vault_break_ui_tests.gd`: 結果金庫扉の存在・成功時表示の回帰。
- `docs/audits/las-vegas-phase-c-p2-visual-polish-2026-08-31.md`: 本レポート。

## 残存課題（P3 / 実機確認）

1. 実機でのBGM / SE / 触覚の5連続プレイ確認。
2. Figma Visual QA BoardへのP2キャプチャ追加（ローカル成果物は揃っている）。
3. ROULETTE固定action dockの重なりを、操作領域を減らさずにさらに磨く場合は別P3として扱う。

P2時点で新規素材、大規模UI再構築、メタ報酬、経済変更は不要と判断した。
