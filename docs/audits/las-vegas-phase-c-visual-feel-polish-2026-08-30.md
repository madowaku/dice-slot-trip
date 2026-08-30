# DICE SLOT TRIP Las Vegas Phase C — Visual & Feel Polish

実施日: 2026-08-30
対象: DICE RACE / DICE TOWER / DICE ROULETTE / TREASURE 21 / DICE POKER / VAULT BREAK

## Phase C Result

Phase Bの経済・BET・transaction・勝敗ロジックは変更していない。今回の実装は、共通の押下フィードバック、結果カードの短いリビール、結果画面の `RETURN / NET` 表記整理に限定した。

| 項目 | 結果 |
| --- | --- |
| Commit | 本レポートを含む独立コミット |
| Branch | `codex/dice-roulette-bgm` |
| Before score | 91 / 100（Phase B） |
| After score | 94 / 100（Visual & Feel再評価） |
| 経済 / transaction | 変更なし |
| 新規画像・音源 | なし |

外部の無料モデルへprivateなリポジトリを送る合法な設定が無かったため、レートリミット節約と情報保護を優先してモデル呼び出しは行わず、ローカルGodot 4.7実行・既存レコーダー・決定的テストで検証した。

## A. 最大の改善点

1. Hubを含む5施設のButtonに、押下時0.06秒の縮小、離上時0.12秒の復帰、hover/focus時の軽い拡大を共通適用した。Pokerは既存の同等モーションを維持し、二重接続を避けた。
2. TOWER / TREASURE 21 / VAULT BREAKの結果確定後に、0.26〜0.28秒のscale-in + fadeを追加した。精算完了後にだけ開始するため、演出がsettlementの条件にならない。
3. ROULETTEの `払戻 / 収支` を `RETURN / NET` に、TREASURE 21の `PROFIT` を `NET` に揃え、BET込みのRETURNと純増減を1秒以内に判読できるようにした。

## B. 変更一覧（Before / Change / After）

| Facility / Screen | Before | Change | After | Size |
| --- | --- | --- | --- | --- |
| HUB / facility cards | カード選択に押した瞬間の反応がなかった | 共通ButtonフィードバックをHubの生成ボタンへ適用 | 6施設を指で選ぶ感触が揃い、カードの字幕と競合しない | XS |
| DICE RACE / BET・STOP | 既存の惰性・順位演出は良いが、STOP入力の視覚反応が施設間で不統一 | 共通ButtonフィードバックをBET/STOP/再戦へ適用 | STOP押下が小さく返り、既存の惰性回転・GOAL待ちを邪魔しない | XS |
| DICE TOWER / RESULT | BUST/CASH OUT結果が即時に全面表示された | settlement後にResultPanelを0.28秒でリビール | BUST直後に理解する一呼吸が入り、RETURN/NETへ視線が流れる | S |
| DICE ROULETTE / RESULT | `払戻 / 収支` が他施設の語彙と異なった。Buttonの押下反応も弱かった | `RETURN / NET` に整理し、共通Buttonフィードバックを適用 | 停止→判定→BET/RETURN/NETの順が読みやすい | XS |
| TREASURE 21 / RESULT | `28 CHIP / PROFIT +8` でBET込みか純増かを読み替える必要があった | `RETURN 28 CHIP（BET込み） / NET +8 CHIP` とリビール | 21/GOLDENの結果理由と実増減を一画面で把握できる | S |
| DICE POKER / 全画面 | 既にHold/RerollとResult introのフィードバックが整っていた | 変更せず基準実装として維持 | 6施設共通のCTA強度に対するリファレンスになった | 維持 |
| VAULT BREAK / RESULT | 解錠判定後の既存0.22秒holdはあるが、結果カードは即時表示 | settlement・進行保存後にResultViewを0.28秒でリビール | 解答→判定→RETURN/NETの順が潰れず、再戦CTAが見える | S |

## C. Hero Moment一覧

| Facility | Hero Moment | Before | After |
| --- | --- | --- | --- |
| DICE RACE | STOP → 惰性回転 → 最終順位 | STOP後の入力は論理的だが視覚的な押下反応は共通でなかった | 0.06秒の押下反応を追加。既存の惰性・GOALの0.28秒待ちを維持 |
| DICE TOWER | ROLL → 成功 / BUST | ダイス確定後から結果カードまでが急に見える | 0.28秒の結果リビールでBUSTを理解する時間を追加 |
| DICE ROULETTE | 減速 → BETエリア停止 → 配当確定 | 既存の0.38/0.42秒停止待ちで、停止前の結果先出しはない | timingは変更せず、CTA反応とRETURN/NET語彙だけ整理 |
| TREASURE 21 | 最終判断 → 合計確定 → 配当判定 | 結果値は正しいがカードが即時表示 | `RETURN（BET込み）` と `NET` を先に読める短いリビール |
| DICE POKER | REROLL → 役完成 / 役昇格 | 既存のResult introと役演出が十分 | 既存Tweenを維持。共通化で二重演出を避けた |
| VAULT BREAK | 回答 → 判定 → 金庫解錠 | 既存のsuccess/failure feedback後に結果が即時表示 | 既存の解錠feedbackを先に残し、結果カードを0.28秒で追従表示 |

## D. Visual Grammar最終状態

| 要素 | 共通ルール | 個性として残したもの | 判定 |
| --- | --- | --- | --- |
| CHIP | 画面上部の残高を常時表示し、結果のBET/RETURN/NETとは別領域に置く | `CHIP` / `CASINO CHIP` / `所持チップ` の短い施設語彙 | PASS（語彙はWATCH） |
| BET | 選択ボタンは既存のselected/disabled状態を維持。押下scaleは共通 | ROULETTEの複数エリア、POKERのchip art | PASS |
| RETURN | stake込みの戻り値として結果領域に表示 | RACEのstatus行、TOWER/VAULTの日本語補足 | PASS |
| NET | 実際の増減を符号付きで表示 | POKERの大きなNET RESULT、TOWERの強調色 | PASS |
| RESULT | 結果確定後にリビール。既存のRACE/ROULETTE/POKER演出を尊重 | BUST / GOLDEN / VAULT BREAK等の固有見出し | PASS |
| REPLAY | 結果直後の主CTAを大きく、BET変更/退出を下位に置く | `NEW RACE` / `PLAY AGAIN` / `NEW VAULT` | PASS |
| BACK | 戻るは再戦より弱くするが、360×800で押せる大きさを維持 | `カジノへ戻る` / `EXIT TO CASINO` | PASS |

## E. 6施設の感情的役割と差別化

| 施設 | このゲームを遊びたい瞬間 | 運 | 判断 | 技能 | テンポ | 独自性 |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| DICE RACE | 狙った目で推しを追い上げたいとき | 50 | 25 | 90 | 55 | STOP精度＋追走＋惰性 |
| DICE TOWER | あと1段だけ欲張りたいとき | 65 | 85 | 10 | 90 | CASH OUTとBUSTの度胸 |
| DICE ROULETTE | 考え込まず一発の停止を見守りたいとき | 95 | 35 | 5 | 92 | 減速・着地・一発配当 |
| TREASURE 21 | 21付近の止め時を当てたいとき | 65 | 90 | 15 | 72 | HIT / CASH OUTの危険予測 |
| DICE POKER | あと1個で役が化けるとき | 55 | 85 | 55 | 75 | HOLD集合の組み替え |
| VAULT BREAK | 金庫の答えを見抜いて開けたいとき | 45 | 90 | 35 | 60 | LOCK配置の推理 |

巡回順は強制せず、脳の切替だけを提案する。

1. 集中と休息: RACE → ROULETTE → TREASURE 21 → TOWER
2. じっくり思考: VAULT BREAK → POKER → TREASURE 21 → ROULETTE
3. テンポ上昇: POKER → RACE → TOWER → ROULETTE

## F. 360×800 Visual QA

Godot 4.7の実描画（GUI renderer）で、Phase Bと同じSubViewport条件を使った。正本キャプチャは `artifacts/audit/las-vegas-phase-c-after/` に保存した。

| 対象 | キャプチャ | 判定 |
| --- | --- | --- |
| HUB | `expansion-console-gui/hub-360x800.png` | PASS |
| DICE RACE | `race/setup_ready-360x800.png`, `rolling-360x800.png`, `stopped-360x800.png`, `final_stretch-360x800.png`, `win-360x800.png` | PASS |
| DICE TOWER | `tower/setup-360x800.png`, `active-floor5-360x800.png`, `bust-floor8-360x800.png`, `success-floor10-360x800.png` | PASS |
| DICE ROULETTE | `expansion-console-gui/roulette-setup-360x800.png`, `roulette-bet-ready-360x800.png`, `roulette-360x800.png`, `roulette-result-360x800.png` | PASS |
| TREASURE 21 | `expansion-console-gui/treasure-setup-360x800.png`, `treasure-360x800.png`, `results/treasure-result-360x800.png` | PASS |
| DICE POKER | `expansion-console-gui/poker-setup-360x800.png`, `poker-help-360x800.png`, `poker-360x800.png`, `poker-result-360x800.png` | PASS |
| VAULT BREAK | `expansion-console-gui/vault-setup-360x800.png`, `vault-360x800.png`, `results/vault-result-360x800.png` | PASS |
| Tall-phone補助 | `tower/*-360x780.png` 3枚 | PASS（補助） |

合計24枚が360×800、補助3枚が360×780で、全27枚が非空画像だった。clipping、overlap、unexpected wrapping、hidden resultは確認されなかった。TOWERの結果時に背後の操作面が薄く残る点は、情報を失わない一方で次Phaseのポリッシュ候補としてWATCHに残す。

## G. Tests / 回帰

Phase BのLas Vegas基準スイートを再実行した。

| Suite | Assertions | Failures |
| --- | ---: | ---: |
| Casino foundation | 36 | 0 |
| Casino models | 248 | 0 |
| Dice Roulette | 80 | 0 |
| Vault Break model | 452 | 0 |
| Casino UI | 172 | 0 |
| Casino expansion UI | 116 | 0 |
| Dice Poker | 55 | 0 |
| Treasure 21 | 47 | 0 |
| Vault Break UI | 59 | 0 |
| **Phase B基準合計** | **1,265** | **0** |
| Phase C visual tests | 29 | 0 |
| **今回のLas Vegas合計** | **1,294** | **0** |

補助確認として `run_tests.gd`（DICE SLOT TRIP基盤）と `run_roll_transaction_tests.gd`（PRE_ROLL/ROLLING/RESULT/MOVEMENTの遷移）も `failures=0` で完了した。Phase C visual testsは、共通Buttonの二重接続防止、全6施設スクリプトのCTA生成、結果リビールのscale/opacity settlingを検証する。

連続プレイについては既存UIスイートの再戦・同額BET・active transactionを含む自動フローを通過。実機5連続の音量・触覚確認は未実施のため、音声と長時間連打耐性はWATCHとする。

## H. Figma

指定のVisual QA Boardは確認を試みたが、Figma MCP Starterのツール呼び出し上限に達して編集できなかった。無理に更新せず、Phase C Afterの実描画を次の場所へ保存した。

`artifacts/audit/las-vegas-phase-c-after/expansion-console-gui/`
`artifacts/audit/las-vegas-phase-c-after/race/`
`artifacts/audit/las-vegas-phase-c-after/tower/`
`artifacts/audit/las-vegas-phase-c-after/results/`

## I. 残存課題と再評価

Phase C後の採点（Phase B 91点から、今回実装が直接改善した項目だけを加点）:

| 評価軸 | 点 |
| --- | ---: |
| Game clarity | 95 |
| Visual hierarchy | 93 |
| Feedback | 95 |
| Feel | 94 |
| Result satisfaction | 94 |
| Replay flow | 93 |
| Cross-game consistency | 93 |
| Facility identity | 95 |
| Mobile readability | 93 |
| Overall polish | 94 |
| **総合** | **94 / 100** |

95点未満の最大3課題:

1. CHIP残高の短い見出しが施設ごとに `CHIP` / `CASINO CHIP` / `所持チップ` と異なる。意味は明確だが、次のXSパスで見出し幅を保ったまま統一できる。
2. 実機5連続プレイでのBGM/SE音量階層と連打時の触覚確認は未取得。現状は既存SE/BGMを変更していないため、Phase Dではなく実機確認のWATCH。
3. FigmaへのPhase Cセクション追加はStarter上限で未反映。ローカルの27枚を使えば次回ボード更新は機械的に行える。

判定: **SMALL POLISH**。Phase Dの大型演出・新規素材・メタ要素は不要。上記の実機確認と任意のCHIP見出し統一を終えれば、Las Vegasを完成扱いにして次ステージへ進める。
