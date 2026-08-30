# DICE SLOT TRIP Las Vegas Phase B 経済最終調整・6施設UX監査

- 実施日: 2026-08-30
- 前提: `las-vegas-phase-a-casino-economy-fix-2026-08-30.md`
- 対象: DICE RACE / DICE TOWER / DICE ROULETTE / TREASURE 21 / DICE POKER / VAULT BREAK
- 方針: 新ゲーム・メタ報酬・大規模レイアウト変更なし。P1と小規模P2だけを実装。
- 経済成果物: `artifacts/audit/las-vegas-phase-b-casino-economy-2026-08-30.json`

## 結論

Phase B後のLas Vegasは **91 / 100程度**。DICE TOWERのBET10だけがCHIP生成器になる問題を解消し、全BETの最適RTPを97.84%へ統一した。Hubの選択地点で6施設の感情的な違いが見え、RACE / TOWER / VAULTの払戻と純収支、TOWER成功結果、TREASUREの実配当が画面上で一致した。Phase Aのtransaction保証は維持され、同額即再戦も1回だけdebitされる。

一方、初心者方針の100ゲーム均等巡回は破産率53.61%、中央値19 CHIPであり、100ゲームを連続滞在するには厳しい。これは「ほぼ確実に破産」ではないが、50ゲーム前後から旅へ戻る判断が自然になる強めの減少速度である。

## A. DICE TOWER Before / After

### 原因

旧倍率はBET10で `1.15×10=11.5→12`、`1.55×10=15.5→16`、`3.25×10=32.5→33` と丸め上振れが生じ、最適方針がその階だけを選択的に回収した。BET20では主要値が整数になり、この補助がないため、10 CHIPだけRTP 102.80%へ逆転していた。

状態価値は次で分解した。

`V_b(10) = round(b × m_10)`

`V_b(f) = max(round(b × m_f), {4V_b(f+1) + V_b(min(10,f+2))}/6)`

各ROLLは1/6でBUST、2～5で+1F、6で+2F。STARTではROLL固定である。

### 比較した3案

| 案 | BET10 / 20 / 50 最適RTP | 体験 | 判断 |
| --- | --- | --- | --- |
| 全倍率×0.96 | 95.29 / 95.60 / 95.01% | 小数が不自然、BET別方針も揃わない | 不採用 |
| 丸め意識の段階調整 | 98.15 / 95.80 / 96.26% | BET10だけ約2.35pt有利 | 不採用 |
| 4F誘惑曲線 | 97.84 / 97.84 / 97.84% | 1F即降りを消し「あと1段」を維持 | 採用 |

採用倍率は `1.10 / 1.25 / 1.50 / 1.80 / 2.00 / 2.30 / 2.70 / 3.10 / 3.60 / 4.20`。

| BET | Before最適RTP | After最適RTP | 差 | After最適方針 |
| ---: | ---: | ---: | ---: | --- |
| 10 | 102.80% | 97.84% | -4.96pt | 0～3F ROLL、4～5F CASH OUT、6F ROLL、7～9F CASH OUT |
| 20 | 98.92% | 97.84% | -1.08pt | 同上 |
| 50 | 99.25% | 97.84% | -1.41pt | 同上 |

BET間RTP差は0.00pt。最適方針のBUST率は46.60%。固定方針は1F回収94.17～95.00%、3F回収96.11%、4F回収97.84%、5F回収94.11%、完走狙い90.96%で、欲張り方に意味が残る。

## B. 初心者300 CHIPシミュレーション

固定BET20、初期300 CHIP、100,000試行、seed 20260830。各セルは `平均 / 中央値 / P10 / P90 / 破産率 / 300以上率 / 100未満率`。

初心者方針は、RACE=ランダム相当STOP、TOWER=最初の到達階でCASH OUT、ROULETTE=HIGH、TREASURE=自動終了までHIT、POKER=最大同値群または最長連続列をKEEPして最大2回REROLL、VAULT=BRONZEで有効LOCKを等確率選択。POKERの初投即終了37.60%は非参加下限としてのみ残し、集計から除外した。POKER初心者RTPは93.14%、最適は94.71%。

| モデル | 10 games | 30 games | 50 games | 100 games |
| --- | --- | --- | --- | --- |
| DICE RACE | 265.85 / 264 / 226 / 308 / 0.00% / 14.81% / 0.00% | 197.15 / 196 / 128 / 268 / 0.01% / 3.43% / 2.86% | 129.96 / 126 / 40 / 220 / 6.12% / 0.95% / 34.12% | 30.79 / 16 / 8 / 84 / 77.25% / 0.04% / 92.16% |
| DICE TOWER | 288.39 / 288 / 254 / 326 / 0.00% / 44.14% / 0.00% | 265.16 / 265 / 202 / 325 / 0.00% / 24.25% / 0.07% | 241.82 / 245 / 163 / 317 / 0.05% / 16.66% / 1.28% | 183.71 / 186 / 71 / 290 / 4.12% / 8.21% / 16.67% |
| DICE ROULETTE | 288.65 / 282 / 176 / 412 / 0.00% / 42.20% / 0.00% | 267.61 / 258 / 56 / 474 / 7.34% / 40.74% / 15.27% | 247.43 / 234 / 10 / 512 / 21.18% / 37.76% / 27.89% | 212.62 / 128 / 4 / 564 / 44.33% / 32.70% / 47.91% |
| TREASURE 21 | 259.02 / 258 / 193 / 323 / 0.00% / 20.31% / 0.00% | 177.90 / 177 / 67 / 287 / 4.12% / 7.72% / 18.19% | 107.83 / 95 / 8 / 238 / 29.50% / 3.22% / 51.69% | 28.91 / 13 / 3 / 87 / 84.35% / 0.45% / 91.20% |
| DICE POKER | 286.44 / 284 / 234 / 342 / 0.00% / 36.83% / 0.00% | 259.09 / 256 / 168 / 354 / 0.00% / 28.36% / 0.84% | 231.42 / 228 / 114 / 354 / 1.14% / 23.08% / 7.39% | 168.53 / 160 / 14 / 334 / 18.82% / 15.29% / 32.76% |
| VAULT BREAK | 260.74 / 270 / 202 / 338 / 0.00% / 31.31% / 0.00% | 183.30 / 176 / 74 / 312 / 4.99% / 11.38% / 16.38% | 116.21 / 116 / 6 / 252 / 30.84% / 4.77% / 49.01% | 35.45 / 14 / 2 / 136 / 80.80% / 1.25% / 86.49% |
| 6施設均等 | 274.95 / 270 / 209 / 348 / 0.00% / 30.28% / 0.00% | 224.48 / 220 / 109 / 346 / 0.93% / 20.48% / 8.16% | 177.30 / 170 / 18 / 329 / 11.53% / 14.65% / 27.11% | 93.27 / 19 / 6 / 267 / 53.61% / 7.33% / 64.67% |
| 毎回ランダム施設 | 274.93 / 272 / 210 / 344 / 0.00% / 29.91% / 0.00% | 224.90 / 221 / 108 / 347 / 1.01% / 20.63% / 8.27% | 176.83 / 170 / 17 / 330 / 12.22% / 14.83% / 27.67% | 93.21 / 19 / 6 / 269 / 53.56% / 7.31% / 64.82% |

### CHIP減少速度の体験評価

- 10 games: 均等巡回の破産0%、P90 348。勝って増える短期体験が十分ある。
- 30 games: 平均224、中央値220、破産0.93%。6施設を一巡し、気に入った施設へ戻る余裕がある。
- 50 games: 平均177、中央値170、破産11.53%。ここが「そろそろ旅へ戻ろう」の中心帯。
- 100 games: 平均93、中央値19、破産53.61%。長時間滞在への圧は強いが、P90は267で勝敗の幅は残る。

初見プレイヤーの自然な滞在は **30～50 games** と推定する。RACE / TREASURE / VAULTだけを初心者方針で100回連続する遊び方は依然厳しいため、Hubで役割差を常時見せることが数理面でも重要である。

## C. 6施設の役割と差別化

| 施設 | 遊びたくなる瞬間 | 運 | 判断 | 技能 | 度胸 | パズル | 予測 | 大勝ち | テンポ | 手触り | リプレイ |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| DICE RACE | 狙った目で推しを追い上げたいとき | 50 | 25 | 90 | 35 | 15 | 45 | 65 | 55 | 90 | 88 |
| DICE TOWER | あと1段だけ欲張りたいとき | 65 | 85 | 10 | 95 | 20 | 35 | 75 | 90 | 85 | 90 |
| DICE ROULETTE | 考え込まず派手な一発に賭けたいとき | 95 | 35 | 5 | 55 | 5 | 25 | 95 | 92 | 80 | 88 |
| TREASURE 21 | 危険な次の一目を読んで止め時を決めたいとき | 65 | 90 | 15 | 80 | 55 | 75 | 60 | 72 | 72 | 87 |
| DICE POKER | 役の伸びしろを考えてダイスを残したいとき | 55 | 85 | 55 | 30 | 70 | 50 | 85 | 75 | 80 | 95 |
| VAULT BREAK | 同じ出目をどの鍵穴へ置くか悩みたいとき | 45 | 90 | 35 | 40 | 95 | 65 | 70 | 60 | 78 | 82 |

RACEとROULETTEは、前者が反射技能・推し・長い追走、後者が低負荷・高テンポ・一発の運で明確に異なる。TREASUREとPOKERは、前者が「続ける/降りる」の危険予測、後者が保持集合を組み替える役作りで異なる。TOWERは判断軸がTREASUREに近いが、毎段1/6 BUSTという度胸と短い反復で別の感情を作る。

### 脳の使い方を切り替える巡回例

1. 集中と休息: RACE → ROULETTE → TREASURE 21 → TOWER
2. じっくり思考: VAULT BREAK → POKER → TREASURE 21 → ROULETTE
3. テンポ上昇: POKER → RACE → TOWER → ROULETTE

順番は強制せず、Hubの短い感情字幕だけで次の負荷を選べるようにした。

## D. UX改善 Before / After

| 対象 | Before | After | 優先度 |
| --- | --- | --- | --- |
| Hub | 施設名＋PLAY。subtitleはtooltipだけ | 6施設すべてに異なる感情字幕を常時表示 | 小P2 |
| RACE結果 | `獲得/+payout`がBET返却込みか不明 | WIN/EVEN/LOSS、最終順位、RETURN（BET込み）、NETを同時表示 | P1 |
| RACE再戦 | 「もう一度」だがBET設定へ戻る | `NEW RACE` | P1 |
| TOWER成功 | status文だけで結果カードなし | 既存BUST overlayを再利用し、階・理由・RETURN・NETを表示 | P1 |
| TOWER再戦 | 「もう一度」がsetup復帰 | 同額即再戦=`PLAY AGAIN`、setup復帰=`CHANGE BET` | P1 |
| TREASURE setup | Phase A前の古い倍率 | 実モデル `0.4/0.55/0.8/1.0/1.7`、GOLDEN `1.25/1.4/1.6` と一致 | P1 |
| TREASURE結果 | 戻るCTAが結果内と共通下部に重複 | PLAY AGAIN / CHANGE BET / カジノへ戻る1本 | P1 |
| VAULT候補 | 有効LOCK発光＋候補数 | 既存の「どこに使うか選択」を維持。重複説明は追加しない | 維持 |
| VAULT結果 | `+reward`が純増に見える | RETURN（BET込み）とNETを分離、setup復帰=`NEW VAULT` | P1 |
| ROULETTE / POKER | 既にBET・RETURN・NETと固有動詞が明確 | 変更なし | 維持 |

### 初回10秒

- RACE: BET対象、STOP、狙う出目、順位勝敗が上部HUDとCTAで見える。
- TOWER: BET、1でBUST、階別倍率、CASH OUTが1画面で見える。
- ROULETTE: CHIP → BET → SPINの順序が明確。
- TREASURE: 「21を目指す」「17からCASH OUT」「GOLDEN自動精算」と正しい倍率がsetupに揃う。
- POKER: BET → DEAL → KEEP → REROLLが固有動詞で明確。
- VAULT: BETとtierを選び、ROLL後に有効な鍵穴を選ぶ流れが見える。

長文ルールは追加していない。優先順位は配置・ラベル・短文を守った。

### 「もう一回」を生む要因

| 施設 | 終了直後の再挑戦理由 |
| --- | --- |
| RACE | 次は狙った面で順位を上げられる |
| TOWER | 次はあと1段上でCASH OUTできる |
| ROULETTE | 次の一発で別の賭け先を試せる |
| TREASURE 21 | 次はHIT/CASH OUTの境界を変えられる |
| DICE POKER | 別のKEEPで高い役を伸ばせる |
| VAULT BREAK | 同じ出目を別の鍵穴へ置ける |

## E. VAULT BREAK寿命

- 30 templates: BRONZE 8 / SILVER 8 / GOLD 8 / BLACK 6。
- 直近2 templateを除外し、通常tierは同structureの連続も抑制。同一templateの最短再登場は3 games後。
- 記憶済み最適RTP: BRONZE 88.706%、SILVER 88.407%、GOLD 89.430%（最大template 93.120%）、BLACK 87.010%。
- 熟練・記憶攻略でも100%未満のため、報酬・重み・再登場間隔は変更しなかった。

## F. 変更ファイル

| ファイル | 理由 |
| --- | --- |
| `scripts/game/dice_tower_model.gd` | TOWER倍率曲線を全BET 97.84%へ統一 |
| `scripts/app/casino_hub_screen.gd` | 施設選択地点に感情字幕を常時表示 |
| `scripts/app/dice_race_screen.gd` | 結果・順位・RETURN・NET・NEW RACE |
| `scripts/app/dice_tower_screen.gd` | 成功overlay、RETURN/NET、transaction-safe PLAY AGAIN |
| `scripts/app/treasure_21_screen.gd` | 正しい倍率、PLAY AGAIN、重複戻るCTA除去 |
| `scripts/app/vault_break_screen.gd` | RETURN/NETとNEW VAULT |
| `tools/audit_las_vegas_economy.py` | BET別DP、初心者方針、全300 CHIP分布、VAULT寿命 |
| `tests/run_casino_tests.gd` | 新TOWER配当表 |
| `tests/run_casino_ui_tests.gd` | Hub/RACE/TOWER UXと即再戦transaction |
| `tests/run_treasure_21_tests.gd` | 実配当copy、CTA一意性 |
| `tests/run_vault_break_ui_tests.gd` | VAULT結果とCTA |
| `tests/record_dice_race.gd` | 現配当の結果capture |
| `tests/record_dice_tower.gd` | 出力先指定と成功結果capture |
| `tests/record_las_vegas_phase_b_results.gd` | TREASURE/VAULT結果の実描画証拠 |

## G. 回帰と実描画

Phase Aと同じ9集計スイートは **1,265 assertions / 0 failures**（Phase A 1,247から+18）。`run_tests.gd`も別枠で `failures=0`。

| Suite | Assertions | Failures |
| --- | ---: | ---: |
| Casino model | 248 | 0 |
| Casino foundation | 36 | 0 |
| Dice Roulette | 80 | 0 |
| TREASURE 21 | 47 | 0 |
| Casino expansion UI | 116 | 0 |
| Casino UI / transaction | 172 | 0 |
| DICE POKER | 55 | 0 |
| VAULT BREAK | 452 | 0 |
| VAULT BREAK UI | 59 | 0 |

360×800の非headless Godot実描画は、Hubを含むexpansion recorder 53/0・`actual_rendering=true`、RACE `layout_fits=true`、TOWER 0 failures、TREASURE/VAULT結果 0 failures・`actual_rendering=true`。文字重なり、画面外CTA、主要play領域の縮小は確認されなかった。

既知のfoundation終了時ObjectDB/resource leak警告はPhase A以前から存在し、assertion failureではない。CasinoBank、legacy save、unknown key、active transaction、settlement receipt、BACK、scene change、restart、360×800、Hubの回帰は維持した。

## 実装優先度と残存課題

今回実装したP1はTOWER経済、誤配当copy、結果収支、成功結果、CTA意味、一意な戻る導線。小規模P2はHub感情字幕。新画像、追加アニメーション、メタ巡回報酬、大規模レイアウトは追加していない。

残る最大3課題:

1. 初心者がRACE / TREASURE / VAULTだけを100 games連続すると破産率77～84%。50 games時点の実機テレメトリで方針分布を確認する必要がある。
2. VAULTのBRONZE / BLACKは熟練RTP 87～89%で、判断時間に対してやや低い。Phase Cで報酬曲線だけを再検討できる。
3. Hub感情字幕は360×800で収まるが小さい。実機の可読性テスト後、カード寸法を変えずにfont/contrastだけ調整する余地がある。

総合すると、Phase Aの「安全な6ゲーム」から、Phase Bでは「その時の気分と脳の使い方で次を選べる6ゲーム」へ進んだ。経済安全性、選択時の差別化、結果理解、再挑戦導線を加点し **85 → 91 / 100** と評価する。
