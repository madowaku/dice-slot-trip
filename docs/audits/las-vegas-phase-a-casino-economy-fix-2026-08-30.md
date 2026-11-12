# DICE SLOT TRIP Las Vegas Phase A 実装・再監査報告

- 実施日: 2026-08-30
- 正本監査: `docs/audits/las-vegas-casino-game-design-audit-2026-08-30.md`
- 対象: DICE RACE / TREASURE 21の経済P0、DICE RACE / DICE TOWERのtransaction統一
- シミュレーション: 20 CHIP、seed 20260830、RACE各条件50,000レース、bankroll各条件100,000セッション

## A. 原因

### DICE RACE

旧仕様は「選択レーサーが1着ならBETの4倍、他は0」なので、RTPは単純に

`RTP = 4.0 × P(選択レーサーが1着)`

となる。ランダム停止では勝率約16.7%でRTP約66.98%だが、選択レーサーの6を60%で止めるモデルでは勝率が約77.5%まで上がり、`4 × 0.775 ≒ 3.10`、RTP約310.60%になる。1回だけでなくゴールまで毎投6を偏らせられ、選択レーサーの累積移動量が他5体を継続的に上回るため、コースギミックでは相殺できなかった。

### TREASURE 21

旧配当は通常17～21が`x0.4 / x0.6 / x1.0 / x1.2 / x2.0`、GOLDEN 18～20が`x1.5 / x1.7 / x2.0`。全状態を動的計画法で「今cash-out」と「1～6を振った後の最適継続」に分解すると、最適方針はG18なら17で継続・19/20で停止、G19なら17/18で継続・20で停止、G20なら17/18で継続・19で停止だった。GOLDEN自動精算と21のx2.0が継続リスクを過剰に補償し、各GOLDENの最適RTPが118.08% / 115.16% / 114.29%、平均115.84%になっていた。

## B. 修正内容

### DICE RACEの3案比較

精度60%時の標準偏差はBET比。RTPは同一50,000レース条件。

| 案 | ランダムRTP | 精度60% RTP | 完全精度RTP | 標準偏差 | 体験・上達感 | 実装規模 | 判断 |
|---|---:|---:|---:|---:|---|---|---|
| 1着のみx0.95 | 15.83% | 73.64% | 95.00% | 0.40 | 初心者の返還が極端に低く、失敗の大半が0 | S | 不採用 |
| 技能対象を1投だけ・1着x5 | 83.42% | 134.35% | 181.63% | 2.22 | 反復する目押しが消え、それでも中級以上が正期待値 | M | 不採用 |
| 見える惰性回転＋最終順位配当 | 82.92% | 90.93% | 97.19% | 0.52 | 毎投のSTOPが実結果へ影響し、上達で損失を明確に抑える | M | 採用 |

採用案はSTOP時点の物理orientationを起点に、保存済み0～9 stepの惰性回転を画面上で進め、その最終orientationをそのままレースへ適用する。裏抽選や表示後の再抽選はない。最終順位配当は1～6位を`x1.8 / x1.0 / x0.8 / x0.6 / x0.4 / x0.3`とし、初心者の連続無返還を減らしながら高精度でも100%未満にした。セットアップと進行ステータスには「STOP後の見える惰性回転で確定」と表示する。

### TREASURE 21

ルールと選択肢は維持し、配当だけを変更した。

- 通常17～21: `x0.4 / x0.55 / x0.8 / x1.0 / x1.7`
- GOLDEN 18～20: `x1.25 / x1.4 / x1.6`

最適停止方針はGOLDEN別に残り、一般方針との差も2.54ポイントある。最適解を覚える価値を残しつつ長期プラスを解消した。

### transaction

RACE/TOWERの直接`spend_chips`・`add_chips`を廃止し、他施設と同じ`CasinoBank.begin_game / update_game / settle_game`へ統一した。

`begin_game（BETを1回だけdebit＋active保存） → game active → pending result固定・保存 → model反映・保存 → settle_game（active削除＋配当credit＋receipt保存） → completed`

RACEの統計更新もsettlementと同じ保存に統合した。pendingにはRACEの開始orientation・惰性step・最終6面対応、TOWERの出目・開始階・roll indexを持たせ、アニメーションより先に保存する。

### 変更ファイル

| ファイル | 理由 |
|---|---|
| `scripts/game/dice_race_model.gd` | 最終順位配当と順位確定 |
| `scripts/app/dice_race_screen.gd` | 見える惰性回転、pending保存、復帰、atomic settlement、ルール表示 |
| `scripts/game/treasure_21_model.gd` | 配当表のP0調整 |
| `scripts/app/dice_tower_screen.gd` | pending出目保存、復帰、atomic settlement |
| `scripts/game/casino_bank.gd` | RACE統計をsettlementへ統合 |
| `tools/audit_las_vegas_economy.py` | Before/After技能曲線、3案、TREASURE 3方針、bankroll再計算 |
| `artifacts/audit/las-vegas-casino-economy-2026-08-30.json` | 再監査の機械可読結果 |
| `tests/run_casino_tests.gd` | 順位配当回帰 |
| `tests/run_casino_ui_tests.gd` | 360×800、BACK、pending中断、再生成、二重精算、勝敗統計 |
| `tests/run_treasure_21_tests.gd` | 新配当のmodel/UI回帰 |

新規画像・音声や外部アセットpackageは追加していない。既存素材でP0の説明性を満たせたため、vendoring/attribution変更もない。

## C. Before / After

| ゲーム | 条件 | Before RTP | After RTP |
|---|---|---:|---:|
| DICE RACE | 初心者相当（ランダム） | 66.98% | 82.92% |
| DICE RACE | 中級相当（6停止精度60%） | 310.60% | 90.93% |
| DICE RACE | 高精度（完全精度） | 400.00% | 97.19% |
| TREASURE 21 | 雑プレイ（常時継続） | 未計測 | 79.53% |
| TREASURE 21 | 一般方針（18以上で停止） | 未計測 | 93.31% |
| TREASURE 21 | 最適戦略 | 115.84% | 95.85% |

RACEの詳細技能曲線は、停止精度16.67% / 25% / 40% / 60% / 80% / 100%で、82.92% / 84.45% / 87.34% / 90.93% / 93.85% / 97.19%。上達に対して単調増加し、完全精度でも負のhouse edgeにはならない。

TREASUREの20 CHIP最適RTPはG18 / G19 / G20で98.09% / 96.13% / 93.34%。GOLDENを平均した95.85%を長期基準とする。

## 300 CHIPシミュレーション

各セルは`平均 / 中央値 / 10%点 / 90%点 / 破産率 / 300以上維持率`。

| 条件 | 10 games | 30 games | 100 games |
|---|---|---|---|
| RACE ランダム | 265.96 / 264 / 226 / 308 / 0% / 14.85% | 197.45 / 196 / 130 / 268 / 0.01% / 3.49% | 30.65 / 16 / 8 / 86 / 77.51% / 0.04% |
| RACE 精度60% | 281.77 / 280 / 240 / 324 / 0% / 29.31% | 245.63 / 244 / 174 / 320 / 0% / 17.30% | 125.34 / 118 / 14 / 252 / 20.88% / 4.25% |
| TREASURE 雑 | 258.84 / 258 / 193 / 322.1 / 0% / 20.26% | 177.67 / 177 / 67 / 287 / 4.08% / 7.60% | 28.94 / 13 / 3 / 89 / 84.25% / 0.43% |
| TREASURE 一般 | 286.71 / 287 / 242 / 331 / 0% / 36.14% | 259.92 / 260 / 183 / 337 / 0% / 25.41% | 169.70 / 167 / 18 / 306 / 11.79% / 11.09% |
| TREASURE 最適 | 291.98 / 293 / 241 / 342 / 0% / 43.54% | 275.46 / 277 / 188 / 361 / 0.01% / 36.53% | 218.16 / 218 / 49 / 375 / 8.31% / 25.32% |
| 6施設均等・RACEランダム | 285.72 / 281 / 219 / 358 / 0% / 36.92% | 255.67 / 252 / 140 / 377 / 0.29% / 30.66% | 165.98 / 145 / 9 / 373 / 30.01% / 19.28% |
| 6施設均等・RACE精度60% | 288.87 / 284 / 223 / 362 / 0% / 38.92% | 263.68 / 259 / 148 / 386 / 0.21% / 33.55% | 188.19 / 173 / 11 / 401 / 24.87% / 23.84% |

単独で雑な方針を100回反復すると破産率は高いが、通常の判断または6施設循環では「ほぼ確実に破産」にはならない。技能・判断による100 games平均残高差はRACEで94.69 CHIP、TREASUREで189.22 CHIPあり、上達価値は明確に残る。

## D. transaction検証

| 経路 | DICE RACE | DICE TOWER | 保証 |
|---|---|---|---|
| 通常勝利/回収 | BET20を1回debit、1位36を1回credit | BET20を1回debit、1F cash-out 23または10F 88を1回credit | receipt再実行は`already_settled`、残高不変 |
| 通常敗北 | 3位16を1回返還し、play=2 / win=1をatomic保存 | BUSTは0でsettle | 二重徴収・二重配当なし |
| BACK | active snapshotを保存して画面離脱 | active snapshotを保存して画面離脱 | BET消失なし |
| シーン切替/アプリ中断 | pending orientation・惰性・6面対応を先に保存 | pending faceを先に保存 | 未確定表示の再抽選なし |
| アプリ終了/再起動/セーブロード | active game idと同じpendingをロード | active game idと同じpendingをロード | 再debitなし |
| 中断復帰 | 保存した惰性を可視再生し同じ6面対応を適用 | 保存した同じ出目を再生・適用 | 結果固定、settlement一度だけ |

legacy save、unknown key保持、active transactionの重複begin/update/settleは既存CasinoBank回帰でも継続確認した。

## E. テスト結果

- 監査時と同じ対象10スイート分類: **1,247 assertions / 0 failures**（監査時1,230から17件追加）
- `run_casino_tests.gd`: 248 / 0
- `run_casino_foundation_tests.gd`: 36 / 0
- `run_dice_roulette_tests.gd`: 80 / 0
- `run_treasure_21_tests.gd`: 43 / 0
- `run_casino_expansion_ui_tests.gd`: 116 / 0
- `run_casino_ui_tests.gd`: 160 / 0
- `run_dice_poker_tests.gd`: 55 / 0
- `run_vault_break_tests.gd`: 452 / 0
- `run_vault_break_ui_tests.gd`: 57 / 0
- `run_tests.gd`: failures=0（全体基盤回帰。上記1,247集計とは別枠）
- Python compile、scoped `git diff --check`: 成功

## F. 再評価

Phase A後のLas Vegasは **85/100程度** と評価する。74/100から、最大のCHIP生成源2件とRACE/TOWERのBET消失リスクを解消し、公平性・保存安全性は大きく改善した。

残存課題は、DICE TOWERの10 CHIPが丸めによりRTP約102.80%であること、RACE/TREASUREを初心者方針だけで100回連続すると破産率が高いこと、TREASURE/VAULTの初回UX、施設ごとの演出・差別化である。TOWERのBET整数表は次Phaseの最優先経済項目、UI・演出・ゲーム差別化はP1/P2として扱う。
