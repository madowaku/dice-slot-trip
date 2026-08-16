# Codex実装指示書：京都ボス「狐火六路陣」v1.0

## 0. 目的

DICE SLOT TRIPの京都ステージ用ボスミニゲームとして、6×6盤面を使った「狐火六路陣」を実装する。

通常マップとは別Sceneの短時間ボスゲームとし、DICE SLOT TRIP本編の「欲しい出目を狙う」「PAIR/TRIPLEも狙う」という3ROLL SLOTの判断をそのままボス戦へ接続する。

作業対象は現行の正本プロジェクトを確認してから着手すること。

既存の通常マップ、3ROLL SLOT、HP/LIFE/COIN、スキル、ステージ遷移を壊さない。

大規模リファクタは禁止。まず独立した京都ボスSceneとして追加する。

---

# 1. ゲームコンセプト

6×6の京都の街路盤を、探検猫がサイコロの出目ぶんだけ上下左右へ移動する。

猫が通った経路には朱色の狐火が残る。

盤面端にある鳥居へ**ぴったり停止**し、現在の鳥居と別の鳥居を朱色の狐火で接続すると「封印」完成。

封印線は金色の結界へ変わる。

3つの封印を完成させれば白狐に勝利。

白狐は毎ターン、盤面へ白い狐火を置いて道を妨害する。

ただし攻撃位置は事前予告する。

---

# 2. 盤面

盤面サイズ：

```text
6 × 6
```

座標：

```text
左上 = (0,0)
右下 = (5,5)
```

移動：

```text
上下左右のみ
斜め移動不可
```

初期版では固定盤面を使用する。

## 鳥居

4つ配置する。

推奨初期配置：

```text
      x0 x1 x2 x3 x4 x5

y0     □  □  □  ⛩B □  □
y1     ⛩C □  □  □  □  □
y2     □  □  🌸 □  □  □
y3     □  □  □  □  □  ⛩D
y4     □  □  🎋 □  □  □
y5     □  □  ⛩A □  □  □
```

Aが初期鳥居。

探検猫はA上から開始。

B/C/Dの3鳥居を好きな順番で巡る。

そのため、

```text
A → B → C → D
A → C → D → B
A → D → B → C
```

など、攻略順をプレイヤーが選べる。

---

# 3. 勝利条件

封印3本完成で即勝利。

```text
seal_count >= 3
```

4つの鳥居をすべて訪問した状態と等価。

3本目の封印完成後は白狐ターンを実行しない。

即座にVICTORYへ遷移する。

---

# 4. 1ターンの流れ

```text
TURN_START
↓
FOX_PREVIEW
↓
ROLL_SLOT
↓
MOVE_VALUE_CONFIRMED
↓
PATH_INPUT
↓
PATH_CONFIRM
↓
CAT_MOVE
↓
SEAL_CHECK
├─ 3封印完成 → VICTORY
└─ 継続
↓
SPECIAL_TILE
↓
FOX_ACTION
↓
DEFEAT_CHECK
↓
TURN_END
```

---

# 5. サイコロ・3ROLL SLOT

既存の3ROLL SLOTシステムを再利用する。

ボス側でPAIR/TRIPLE判定やスロット計算を複製しない。

既存側から最終的に、

```gdscript
move_steps: int # 1〜6
```

を受け取る。

この値が今回移動しなければならないマス数。

例：

```text
出目4
↓
4マスちょうど移動
```

途中で止まることは禁止。

余らせることも禁止。

---

# 6. DICE SLOT TRIPらしい二重判断

例：

```text
現在のSLOT

[3][3][?]
```

鳥居まで4マス。

プレイヤーは、

```text
3を狙う
→ TRIPLEを狙える
→ ただし鳥居には届かない

4を狙う
→ PAIR/TRIPLEは崩れる
→ しかし鳥居へぴったり到達して封印完成
```

という判断を行う。

この構造を壊さないこと。

---

# 7. 移動ルール

出目Nなら、Nマス必ず移動。

途中で何度でも曲がってよい。

ただし以下は禁止。

```text
・斜め移動
・白狐の狐火マスへ進入
・1ターン中に同じマスを2回通る
・盤外へ移動
```

過去ターンに通ったマスへ再び入ることは可能。

完成済みの金色結界上も通行可能。

現在の朱色狐火上も、別ターンなら通行可能。

---

# 8. 操作方法

MVPではドラッグ必須にしない。

まず確実な「1マスずつタップ」方式で実装する。

出目確定後、

```text
残り 4
```

を表示。

猫に隣接する合法マスだけハイライト。

1マスタップするごとに、

```text
残り 4
↓
残り 3
↓
残り 2
...
```

と減らす。

直前のマスを再タップした場合のみ、

```text
入力取り消し
```

として1手戻せる。

これは実ゲーム上の「同じマス再訪」には数えない。

入力ルート完成後、

```text
[この道で進む]
```

を有効化。

確定するまでは猫を実際には移動しない。

---

# 9. 到達可能地点プレビュー

出目確定時にDFSで、

```text
「現在位置からちょうどN歩で到達可能なセル」
```

を計算する。

条件：

```text
・上下左右
・盤内
・白狐火を通らない
・同一ターン内セル再利用なし
```

到達可能な終点を薄く光らせる。

その中に未訪問鳥居がある場合、その鳥居を強く光らせる。

表示例：

```text
あと4なら、ここまで行ける
```

既存のピンポイント表示を安全に再利用できる場合は利用してよい。

既存システムへの無理な結合はしない。

---

# 10. 狐火経路の内部表現

朱色狐火・金色結界は「セル」ではなく、セル間の**辺**として記録する。

例：

```text
(2,5) → (2,4)
```

を1本のEdgeとして保存。

推奨：

```gdscript
class_name FoxFireEdge
extends RefCounted

var a: Vector2i
var b: Vector2i
```

保存時にはa/b順を正規化して、同じ辺を重複登録しない。

Runtime State：

```gdscript
var active_edges = {}
var sealed_edges = {}
```

`active_edges`

現在の鳥居から伸ばしている朱色狐火。

`sealed_edges`

封印済みの金色結界。

---

# 11. 朱色狐火

プレイヤーが移動した辺を、

```text
active_edges
```

へ追加。

見た目：

```text
明るい朱色
少し揺らぐ狐火
```

過去に同じ辺を通った場合は重複登録しない。

---

# 12. 封印判定

猫が移動終了時に、

```text
未訪問の鳥居
```

へぴったり停止した場合に判定。

現在の封印開始鳥居から、その鳥居まで、

```text
active_edges
```

を使って接続されていれば封印成立。

通常は移動軌跡が連続しているため自然に成立する。

将来Lv5の「線切断」が入っても同じ判定を使えるよう、BFS/DFSで接続確認する。

---

# 13. 封印完成処理

例：

```text
⛩A
 │
 🔥
 └🔥🔥⛩B
```

到達すると、

```text
封印！
```

演出。

現在の`active_edges`のうち、開始鳥居と到着鳥居を結ぶ連結成分を、

```text
朱色
↓
金色
```

へ変化。

`sealed_edges`へ移動。

残った不要な朱色枝は消してよい。

その後、

```gdscript
seal_count += 1
current_torii = destination_torii
destination_torii.visited = true
active_edges.clear()
```

次の封印を開始。

---

# 14. 鳥居のルール

同じ鳥居を再びゴールにしても新しい封印にはならない。

未訪問鳥居のみ新規封印対象。

UI：

```text
未訪問鳥居
→ 朱色

現在の鳥居
→ 金色＋猫

訪問済み鳥居
→ 金色
```

HUD：

```text
封印 0/3
封印 1/3
封印 2/3
封印 3/3
```

---

# 15. 白狐の狐火

白狐は盤面奥に座っている。

白狐の妨害は「白い狐火」。

内部表現：

```gdscript
var white_fire_cells: Dictionary
```

白狐火セルへ猫は進入不可。

白狐火は以下には通常配置しない。

```text
・鳥居
・猫の現在位置
・既存白狐火
・朱色狐火上
・完成済み金色結界上
```

初期難易度では空き地のみ対象。

---

# 16. 白狐攻撃予告

白狐の行動は原則、事前にプレイヤーへ見せる。

例：

```text
△
```

あるいは白い火の半透明表示。

HUD：

```text
次の狐火
```

盤面上にも同時表示する。

プレイヤーは、

```text
ここが次に塞がれる
↓
今のルートを急ぐ
迂回する
別の鳥居を狙う
```

を判断できる。

完全な不意打ちにしない。

---

# 17. 白狐AI難易度

難易度はデータ化する。

```gdscript
class_name FoxFireDifficultyConfig
extends Resource

@export var level := 1
@export var attack_interval := 0
@export var smart_targeting := false
@export var candidate_count := 1
@export var enable_line_cut := false
@export var enable_special_tiles := false
```

基本方針：

```text
Lv1
白狐火なし
ルール習得用

Lv2
2ターンごとに白狐火1個
攻撃先は完全表示

Lv3
毎ターン白狐火1個
攻撃先は完全表示

Lv4
鳥居付近・現在の攻略ルート付近を優先
攻撃先は完全表示

Lv5
通常狐火＋一定間隔で封印線切断
切断位置も1ターン前に予告

Lv6+
狐火候補2か所を表示
実際に置くのは片方
特殊マス有効
```

LAP→Levelの対応はResourceまたはステージデータ側に置き、コードへ固定しすぎない。

初期値案：

```text
LAP 1       Lv1
LAP 2〜4    Lv2
LAP 5〜8    Lv3
LAP 9〜12   Lv4
LAP 13〜16  Lv5
LAP 17+     Lv6
```

後から容易に調整可能にする。

---

# 18. Lv4 AI

完全ランダムではなく候補セルへスコアを付ける。

初期案：

```text
未訪問鳥居の隣接セル       +4
猫→未訪問鳥居の短経路上   +3
active_edges隣接セル       +2
猫から極端に遠い          -1
```

最高スコアから選択。

同点だけRNG。

ただし選ばれたセルはプレイヤーターン開始前に予告する。

AIが後出しでプレイヤー経路を見て場所を変えることは禁止。

---

# 19. Lv5 線切断

MVP完成後に追加する。

白狐は一定間隔で、

```text
active_edges
```

の1本を切断可能。

対象条件：

```text
・active edge
・鳥居直結edgeではない
・猫直下のedgeではない
```

対象は必ず前ターンから予告。

発動時：

```text
active_edges.erase(target_edge)
```

朱色狐火がプツンと消える。

白狐火セルへ変換はしない。

プレイヤーが後から同じ辺を再度通れば修復できる。

封印判定は辺接続BFSを使うため、そのまま機能する。

---

# 20. Lv6 二択狐火

ターン開始時：

```text
△A
△B
```

の2候補を表示。

プレイヤー行動終了後、

A/Bどちらか一方へ白狐火。

候補自体は途中で変更しない。

RNGはBattle専用の`RandomNumberGenerator`を使用。

seed固定テストが可能な構造にする。

---

# 21. 移動不能時

選択された出目で合法なN歩ルートが1本もない場合、

```text
この出目では道を引けない！
```

と表示。

既存の振り直し・スキル等が使える場合は使用可能。

それでも変更せず確定する場合、

```text
MISS
```

として猫は移動しない。

その後、通常通り白狐ターンへ進む。

即敗北にはしない。

---

# 22. 敗北条件

任意ターン数による強制ゲームオーバーは設けない。

白狐火により、

```text
現在位置から未訪問鳥居のいずれにも
通常床を通って到達不能
```

になったら敗北。

判定は出目を無視した通常BFSでよい。

つまり、

```text
白狐に街路を完全封鎖された
```

状態。

表示：

```text
六路、封鎖。

白狐に道を閉ざされた……
```

その後BattleResultを返す。

HP/LIFE減少処理はボスScene内部で直接行わず、既存GameSession側へ任せる。

---

# 23. 特殊マス

まずコアゲームを完成させ、その後Feature Flagで追加。

v1候補は2種類。

## 桜

```text
SAKURA
```

猫が桜マスへぴったり停止した場合、

白狐火を1個消去できる。

対象が存在する場合だけ、

```text
浄化する狐火を選んでください
```

へ遷移。

1セル選択して削除。

## 竹林

```text
BAMBOO
```

竹林へ入った場合、

入った方向と同じ方向へ抜けなければならない。

例：

```text
→ 🎋 →
```

竹林上で移動が終了した場合は、次ターン最初の1歩も直進方向を維持する。

必要ならStateへ、

```gdscript
var forced_exit_direction: Vector2i
```

を保持する。

---

# 24. 今回実装しない特殊マス

以下はデータ型だけ将来追加可能にして、初回実装では作り込まない。

```text
千本鳥居
枯山水
飛び石
```

コアルール確認後に追加する。

---

# 25. 街区封印（囲み）

将来機能。

初回MVPではOFF。

```gdscript
@export var enable_block_seal_bonus := false
```

将来的には朱色＋金色の辺で閉ループが完成し、内部に1セル以上存在する場合、

```text
街区封印！
```

を発生させる。

想定ボーナス：

```text
・白狐火1個除去
・スコア加算
・白狐行動1回スキップ
```

このため狐火経路をEdgeで保存する。

---

# 26. 御朱印のボス効果

京都通常マップで取得した御朱印をBattleContextから受け取る。

## 伏見稲荷

通常は鳥居Aスタート。

所持時：

```text
4つの鳥居から開始地点を自由に選べる
```

PRE_BATTLE画面で選択。

## 八坂

最初の白狐行動を1回遅延。

## 清水寺

1戦1回、

```text
3ROLL SLOTの全振り直し
```

既存機能へ接続。

## 天龍寺

1戦1回、

```text
確定出目を +1 または -1
```

1〜6範囲内。

## 満願

4枚所持時。

1戦1回、

```text
次の白狐行動を完全無効化
```

事前に「満願札」をONにして使用。

---

# 27. UI構成

Portrait前提。

```text
FoxFireSixRoutesBattle : Control
│
├─ Background
│
├─ TopHUD
│  ├─ TitleLabel
│  ├─ SealCounter
│  ├─ TurnLabel
│  ├─ HPDisplay
│  └─ CoinDisplay
│
├─ FoxActionBar
│  ├─ NextFoxFireLabel
│  ├─ BlessingDisplay
│  └─ ManganButton
│
├─ BoardRegion
│  ├─ KyotoBoard
│  ├─ FoxBossVisual
│  ├─ TrailLayer
│  ├─ PreviewLayer
│  └─ BoardInputBlocker
│
├─ MoveInfo
│  ├─ MoveValueLabel
│  └─ RemainingStepsLabel
│
├─ SlotHost
│  └─ 既存3ROLL SLOT
│
├─ ActionBar
│  ├─ UndoButton
│  └─ ConfirmPathButton
│
├─ MessageLayer
├─ ResultOverlay
│
└─ Controller
```

盤面を画面の主役にする。

---

# 28. BoardCell

```gdscript
enum CellType {
    NORMAL,
    TORII,
    SAKURA,
    BAMBOO
}
```

Runtime：

```gdscript
class_name FoxFireBoardCell
extends RefCounted

var position: Vector2i
var type: int
var torii_id := -1
var visited_torii := false
var has_white_fire := false
```

---

# 29. BattlePhase

bool乱立を避ける。

```gdscript
enum BattlePhase {
    INTRO,
    PRE_BATTLE,
    TURN_START,
    ROLL_SLOT,
    PATH_INPUT,
    CAT_MOVING,
    SEAL_RESOLVE,
    SPECIAL_RESOLVE,
    FOX_ACTION,
    TURN_END,
    VICTORY,
    DEFEAT,
    RESULT
}
```

現在入力可能かはPhaseのみを基準に判断する。

---

# 30. Runtime State

```gdscript
class_name FoxFireBattleState
extends RefCounted

var phase: int

var turn_number := 0
var difficulty_level := 1

var cat_position: Vector2i
var current_torii_id: int

var move_steps := 0
var current_input_path: Array[Vector2i] = []

var active_edges = {}
var sealed_edges = {}

var white_fire_cells = {}

var visited_torii = {}
var seal_count := 0

var fox_preview_cells: Array[Vector2i] = []

var forced_exit_direction := Vector2i.ZERO

var mangan_available := false
var mangan_armed := false

var kiyomizu_available := false
var tenryuji_available := false
```

---

# 31. Controller責務

```text
FoxFireSixRoutesController.gd
```

担当：

```text
・ターン遷移
・移動可能判定
・DFS到達候補
・経路入力
・封印接続判定
・白狐AI
・特殊マス
・勝敗
・乱数
```

UIからStateを直接書き換えない。

---

# 32. View責務

```text
FoxFireSixRoutesView.gd
```

担当：

```text
・盤面描画
・猫表示
・朱色狐火
・金色結界
・白狐火
・候補セル
・移動可能セル
・アニメーション
・HUD
・SE
```

Controllerへ入力イベントだけ返す。

---

# 33. Signal

最低限：

```gdscript
signal cell_pressed(position: Vector2i)
signal undo_requested
signal path_confirm_requested

signal phase_changed(phase)
signal move_steps_changed(value)
signal remaining_steps_changed(value)

signal seal_completed(count)
signal white_fire_changed()

signal battle_finished(result)
```

---

# 34. BattleResult

```gdscript
class_name FoxFireBattleResult
extends RefCounted

var victory: bool
var defeat_reason: String

var turns_used: int
var seal_count: int

var total_steps: int
var white_fire_placed: int
var white_fire_removed: int

var rerolls_used: int
var blessings_used: int

var difficulty_level: int
```

将来用：

```gdscript
var city_blocks_sealed := 0
var line_cuts_repaired := 0
```

---

# 35. ファイル案

```text
res://boss/kyoto/fox_fire_six_routes/

FoxFireSixRoutesBattle.tscn
FoxFireSixRoutesBattle.gd
FoxFireSixRoutesController.gd
FoxFireSixRoutesView.gd

data/
  FoxFireBattleState.gd
  FoxFireBattleResult.gd
  FoxFireDifficultyConfig.gd
  FoxFireBoardCell.gd
  FoxFireEdge.gd

ui/
  FoxFireBoard.tscn
  FoxFireBoard.gd
  FoxFireCell.tscn
  FoxFireCell.gd
  FoxFireHUD.tscn

effects/
  PlayerFoxFireTrail.tscn
  WhiteFoxFire.tscn
  SealCompleteEffect.tscn
```

既存ディレクトリ構成に合わせて変更してよい。

無理にこの構造へ既存コードを合わせない。

---

# 36. 実装Slice

## Slice 1：核

実装：

```text
6×6盤
4鳥居
猫
出目1〜6仮入力
N歩移動
経路タップ
ぴったり鳥居停止
3封印で勝利
```

この時点では白狐AIなし。

必ず実機/画面で遊べる状態にする。

## Slice 2：3ROLL SLOT統合

仮入力を削除。

既存3ROLL SLOTからmove_stepsを受け取る。

PAIR/TRIPLE挙動を壊さない。

## Slice 3：白狐火

```text
攻撃予告
白狐火配置
通行禁止
敗北判定
```

Lv2/Lv3まで。

## Slice 4：御朱印

4種＋満願。

## Slice 5：Lv4 AI

鳥居優先AI。

## Slice 6：特殊マス

桜・竹林。

## Slice 7：Lv5/Lv6

線切断・2候補。

## Slice 8：演出

```text
猫移動
朱色狐火
封印金化
白狐火
勝利演出
SE/BGM
```

## Slice 9：囲み

コアが十分面白いことを確認してから実装。

---

# 37. 必須テスト

### MOVE-01

出目3。

合法な3マス経路を入力。

→ 移動成功。

### MOVE-02

出目3で2マスだけ入力。

→ Confirm不可。

### MOVE-03

同一ターン中に同じセルへ再進入。

→ 不可。

### MOVE-04

白狐火へ進入。

→ 不可。

### MOVE-05

過去ターンに通ったセル。

→ 通行可能。

### MOVE-06

出目4でちょうど鳥居停止。

→ 封印。

### MOVE-07

鳥居を途中通過して別セル停止。

→ 封印されない。

### MOVE-08

訪問済み鳥居へ停止。

→ 新規封印されない。

### SEAL-01

3本目完成。

→ 白狐行動なしでVICTORY。

### FOX-01

予告セルと実際の配置セルが一致する。

### FOX-02

白狐火配置後、そのセルを猫が通れない。

### FOX-03

全未訪問鳥居への経路が遮断。

→ DEFEAT。

### SLOT-01

PAIR/TRIPLE処理が通常システムと同じ。

### SLOT-02

ボス側がPAIR/TRIPLEロジックを重複保持していない。

### RNG-01

seed固定。

→ 白狐候補生成を再現可能。

---

# 38. UX上の重要事項

ルール説明を文章で読ませすぎない。

初回説明は3枚程度。

```text
1.
出目の数だけ、猫で道を引こう！

2.
鳥居へぴったり止まると封印！
3つつなげば勝利！

3.
白い狐火は通れない。
次に塞がれる場所を見て道を選ぼう！
```

実プレイ中は盤面ハイライトで理解させる。

---

# 39. 初期演出

通常京都マップの最後からボスSceneへ遷移。

白狐が盤面奥に現れる。

6×6の京都街路が淡く発光。

探検猫が鳥居Aへ立つ。

白狐：

```text
「では、京の六路を巡ってみよ。」
```

タイトル：

```text
狐火六路陣
鳥居を3つ結び、結界を完成させろ！
```

そのまま1ターン目へ。

---

# 40. 勝利演出

3本目完成。

朱色狐火が一気に金色へ。

3本の結界が京都盤を走る。

白狐の白い狐火が消える。

白狐：

```text
「見事。道は、しかと繋がった。」
```

BattleResultをGameSessionへ返す。

既存の京都クリア・LAP進行・回復等へ接続。

---

# 41. 最重要方針

このボス戦の面白さは、

```text
大きい数字を出すこと
```

ではない。

```text
今、自分が欲しい数字を狙うこと
```

にある。

そのため、

```text
6が常に最強
```

になる調整は禁止。

鳥居への正確停止、白狐火、盤面形状によって、

```text
「今回は2が欲しい」
「ここは4」
「TRIPLEを捨てて5を取る」
```

が自然に発生することを最優先する。

まずSlice 1〜3まで実装し、実際に10戦以上プレイしてから特殊マス・線切断・囲みを追加すること。