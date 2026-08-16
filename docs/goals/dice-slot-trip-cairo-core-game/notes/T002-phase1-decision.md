# PHASE 1 Cairo Core Game Decision

## 1. 現行仕様

- 正本は90マスの `v06_cairo_course.json` と `V06PlaySession`。1周は概ね24〜27投、3投SLOTは7〜10セット。
- MISSIONは「COIN累計12」「PAIR/STRAIGHT/TRIPLE合計5」「ノーダメージ」の3件常設。周回ごとにリセットし、直接のTRIP COIN報酬はない。
- 通常SLOTは `MIX=COIN+1 / PAIR=SKILL+1 / STRAIGHT=SKILL+2 / TRIPLE=SKILL READY`。
- SKILLはゲージ3で、READY時に次の出目を1回指定できる。
- RESTはHP+1、購入済み強化でHP+2、HP満タン時はCOIN+1。
- 現行coinsは周回限定ウォレット。COINマスは基本+2、周回開始時に0へ戻る。SCOREは移動歩数のみ。
- コイン商品は RISKガード2、ハート強化2、ボスの盾3、先行スタート4、ボス停止5。カイロ画面では購入可能だが説明が略記号中心。
- CASINO CHIPは未実装。ボス勝敗後のコイン換金も未実装。

## 2. 発見した問題

- 3つのMISSIONが小さく並び、優先目標・報酬・意味が弱い。COIN12はほぼ自然達成、ノーダメージは受動的で、プレイ方針を十分変えない。
- MISSION ID (`cairo_coin15`, `cairo_triple2`) と実際の目標値12/5が不一致。
- 2投後のリーチ判定は存在するが、短時間表示で役知識を前提とし、必要出目とMISSION同時進行が十分伝わらない。
- SLOTとSKILLが直結しているため、役を「通貨報酬」に切り替える際に二重報酬化しやすい。
- コイン画面は機能しているが、`RISK ×0` などの略記号、カテゴリなし、発動タイミング・回数・購入状態の弱さが初見理解を妨げる。
- 90マス実行系と旧58マス資料が混在し、経済・QA判断を誤らせる。
- 旧資料のコイン緊急復帰は実装・テストでは削除済み。再導入するとLIFE設計と競合する。
- 画面テストには既存のQAスコア期待値1件の赤があるため、新規変更の回帰と分離が必要。

## 3. 採用する新仕様

### MISSION

- 1周につきランダム1件。選択結果と進捗を保存し、ロードや再開で抽選し直さない。
- 1回だけ達成報酬を付与し、報酬はTRIP COIN。段階ランクと3件同時表示は廃止する。
- 初期カタログ候補:
  - `DICE_HIGH_8`: 5または6を8回止める、報酬6。
  - `DICE_LOW_8`: 1または2を8回止める、報酬6。
  - `SLOT_ROLE_6`: PAIR以上を6回成立、報酬6。
  - `SLOT_STRAIGHT_2`: STRAIGHTを2回成立、報酬8。
  - `SLOT_TRIPLE_2`: TRIPLEを2回成立、報酬10。
  - `MAP_RISK_3`: RISKへ3回止まり生存、報酬7。
  - `TRIP_SPEND_12`: ショップ／EVENT／ボス準備で12枚使う、報酬6。
  - `TRIP_KEEP_20`: ボスゲート到達時に20枚残す、報酬5。
- 達成率目標は一般プレイ45〜70%、家族の習熟プレイ60〜85%。実測20周で上下15ポイント以上ずれたMISSIONは目標値を再調整する。

### SLOT

- 通常マップの成立報酬を `PAIR +1 / STRAIGHT +2 / TRIPLE +3 / MIX +0 TRIP COIN` に置き換える。現行SKILLチャージとMIX+1は同時に残さない。
- ボス戦のPAIR/STRAIGHT/TRIPLE固有効果は現状維持し、通常マップのTRIP COIN報酬は重ねない。
- 2投後は「あと1回」「必要な出目」「成立役」「獲得COIN」を持続表示する。
- アクティブMISSIONが同じ役を要求する場合は `ダブルチャンス：SLOT + MISSION` を同じ表示帯に出す。
- 成立演出は現在の短いインライン演出を維持し、確認モーダルを増やさない。

### SKILL / REST

- 好きな出目を次の1回だけ指定する能力は維持。
- HPが減っているRESTはHP回復を最優先。通常+1、ハート強化時は合計+2。
- HP満タンかつSKILL未満ならSKILL +1。HP満タン時のCOIN +1は廃止する。
- HPとSKILLが両方満タンなら追加報酬なし。ハート強化はHP回復が起きるまで消費しない。

### TRIP COIN / CASINO CHIP / SCORE

- 現在の `coins` をTRIP COINの互換実体として使い、UI名称を段階的に統一する。
- TRIP COINは周回内限定。ボス終了後、未変換残高を `floor(TRIP COIN / 5)` CASINO CHIPへ一度だけ変換し、端数は消える。
- CASINO CHIPは永続値として別フィールドに保存し、旧coinsから暗黙変換しない。
- ボス前には `今のままなら N CHIP` を表示する。消費を選ぶほど攻略が楽になり、残すほどCHIPが増える構造にする。
- SCOREは累計移動歩数のまま。通貨・MISSION・ボス報酬を加算しない。

### BOSS / SHOP

- 既存のボスの盾3、先行スタート4、ボス停止5と、その効果を維持する。
- コイン画面は手動で開く。毎ターンやボス前の購入確認は出さない。
- ボス初投前だけ購入できる現行制約を維持する。

## 4. 採用しない案・今回延期する案

- `PAIR +1 / STRAIGHT +3 / TRIPLE +5` は初期値としては不採用。習熟者の役成立率が高く、MISSION報酬とCHIP変換を合わせると残高が膨らみやすい。
- 見えない「SLOT報酬は1周12枚まで」は不採用。上限より、見える報酬値と実測調整を優先する。
- COIN緊急復帰は再導入しない。現行LIFE3設計とテストを正とする。
- 旧58マス資料を経済正本にしない。
- 京都ボス再設計、ラスベガスでのCHIP消費、全ステージ共通UI化はPHASE 1の最初の実装スライスから外す。
- 常設予約効果アイコンと初回チュートリアルは、コイン画面本体の理解度を確認した後の第2 UIスライスへ延期する。

## 5. COIN経済の推奨数値

- 現行総獲得: 低29〜34、標準35〜40、高44〜48。
- 現行有用支出: 軽量2〜4、標準5〜9、最大16〜26。
- 新SLOT報酬は置き換え後、ランダム時約0.58枚/セット。7〜10セットで約4〜6枚だが、現行MIX+1が消えるため標準プレイの純増差は小さい。
- 習熟プレイでは約8〜18枚/周まで上がり得るため、初期値は1/2/3とし、+1/+3/+5へ上げない。
- MISSION報酬は5〜10枚。標準は6、難しい特定役だけ8〜10。
- 5:1交換は維持。標準プレイで8〜16枚使った場合、残20〜35枚、4〜7 CHIP/周を初期目標とする。
- 20周の中央値が8 CHIP超ならSLOT/MISSION報酬を下げ、3 CHIP未満ならMISSION報酬か入手経路を上げる。価格2/2/3/4/5は当面据え置く。

## 6. UI変更案

- PHASE 1の対象はCairo `V06PlayScreen`。`JourneyStageScreen` は後続の共通化対象。
- ヘッダーを `コインショップ`、その直下に `所持TRIP COIN：N`。
- `旅の道具` と `ボスの準備` の2タブ。各タブ内で1商品ずつ左右送り。
- 商品ごとに、名前、短い効果、発動タイミング、1回限り／消費条件、価格、状態、購入ボタンを表示。
- 状態は `未所持 / 所持中 / 次のボス戦で発動 / コイン不足` を明示。
- 360×640では説明を2〜3行に制限し、購入・閉じるボタンを下部固定。イラストは説明を圧迫しない。
- MISSION帯は1件に拡大し、`この周回のMISSION`、条件、進捗、報酬を常時表示。
- SLOT帯は `3回の出目で役を作る` を常設し、2投後は必要出目をゴースト表示する。

## 7. セーブ互換方針

- コイン画面のコピー／カテゴリ／状態表示だけでは保存形式を変えない。既存stage flagsをそのまま使う。
- MISSION変更時はnested mission schemaを3へ上げる。旧schema 2の3件MISSIONはその周回だけlegacy modeで継続し、次周回からランダム1件へ切り替える。
- schema 3は `active_id`, `selection_seed`, `progress`, `completed`, `reward_claimed`, `legacy_mode` を保存する。報酬は二重付与できない。
- 既存 `player.coins` はTRIP COIN互換キーとして維持する。
- CASINO CHIPはoptional persistent field、既定値0。旧SAVE読み込み時に旧coinsを変換しない。
- ボス後の変換には `cashout_applied` と変換結果を保存し、再ACK・再ロードで増えないようにする。
- 外側save schema/course versionの変更は、新フィールドのvalidatorとmigration設計が確定した時点で判断する。

## 8. 実装順

1. コイン商品カタログへ自然文・カテゴリ・タイミング・状態メタデータを追加し、CairoショップUIをワイヤー最優先項目へ合わせる。
2. コインショップのユニット／画面／360×640回帰を追加する。
3. MISSION schema 3、ランダム1件、報酬一度限り、legacy lap migrationを実装する。
4. 通常SLOT報酬をTRIP COINへ置換し、MISSIONとのダブルチャンス表示を実装する。
5. REST優先順位とSKILLチャージ源を変更する。
6. CASINO CHIP保存、ボス後一度だけ変換、ボス前プレビューを実装する。
7. 常設予約効果アイコン、初回コインチュートリアル、Amazon/Kyotoの共通化を行う。

## 9. テスト項目

- Coin catalog: 5商品のカテゴリ、価格、短文、タイミング、持続、active状態。
- Coin purchase: 不足、重複、禁止フェーズ、ボス初投後、SAVE復元、1回だけ消費。
- Coin UI: 2タブ、カテゴリ内ページ数、所持数、状態文、ボタン文、閉じる、360×640非クリップ、全タッチ領域。
- Mission: 1件だけ選択、ロードで固定、各8候補の進捗、報酬一度だけ、次周回再抽選、schema2 legacy lap移行。
- Slot: MIX 0、PAIR 1、STRAIGHT 2、TRIPLE 3、SCORE不変、ボス役効果不変、再ACK二重報酬なし。
- Reach: 必要出目、あと1回、MISSION double chance、成立後の短い自動復帰。
- REST: HP不足通常/強化、HP満タンSKILL+1、両方満タン、強化flag非消費、SAVE復元。
- Cashout: 勝敗双方、5未満、5、8、25、再ACK、再ロード、次周回、旧SAVE CHIP=0、SCORE不変。
- Full regression: editor parse, v06 mission/coin/session/tile/save/boss/screen suites, legacy suite, Amazon/Kyoto smoke。
- 既存 `run_v06_play_screen_tests.gd` のQA route-score 1件は既知赤として別管理し、新規失敗数を増やさない。
