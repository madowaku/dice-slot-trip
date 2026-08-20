# 京都v2 Godotステージデータ仕様

## 1. 目的

京都ステージ「千年碁盤の京都」をv2へ改修する。

主目的は以下。

- カイロで確立した通常プレイUI・MISSION・SLOT・COIN・ITEM・SKILL文法を京都へ共通化
- 通常マップ上の分岐と選択EVENTを大幅削減
- ITEM密度を上げる
- 御朱印を「ぴったり着地」ではなく通過取得にする
- 近道を2本だけ残し、明確なリスク／リターンにする
- 最終盤で「新ボス戦」「現パズルボス戦」を選択可能にする
- 既存の京都コードを全面破棄せず、現在の `KyotoCourseModel` / `KyotoJourney` をv2対応へ拡張する

---

# 2. 番号体系

設計時に使用した `0〜89` は**デザイン番号**。

Godot内部では既存実装との互換性を優先して、

- `main:1` ～ `main:90`
- START = `main:1`
- BOSS = `main:90`

を維持する。

変換規則:

```text
internal_number = design_number + 1
```

例:

```text
設計 0  → main:1
設計 20 → main:21
設計 32 → main:33
設計 71 → main:72
設計 87 → main:88
設計 89 → main:90
```

プレイヤーUIも `1/90 ～ 90/90` 表示を基本とする。

---

# 3. ファイル構成

既存ファイルを基本的に維持する。

```text
data/stages/
  kyoto_thousand_year_grid.json

scripts/game/
  kyoto_course_model.gd
  kyoto_journey.gd
  white_fox_battle.gd

data/bosses/
  white_fox_seal.json
  kyoto_direct_duel.json     # 新ボス実装時
```

京都ステージJSONは既存ファイルを更新し、

```json
"schema_version": 2
```

とする。

---

# 4. ステージ基本メタデータ

```json
{
  "schema_version": 2,
  "course_version": "kyoto_v2_90_core_1",
  "stage_id": "kyoto_thousand_year_grid",
  "display_name": "千年碁盤の京都",
  "space_count": 90,
  "start_space_id": "main:1",
  "boss_space_id": "main:90",
  "branch_count": 2,
  "route_count": 2
}
```

`branch_count` は通常マップの近道2本のみを数える。

最終ボス選択は通常ルート分岐とは性質が異なるため、`boss_choice` として別管理する。

---

# 5. 地区データ

```json
"districts": [
  {
    "id": "fushimi",
    "name": "伏見稲荷",
    "range": [1, 22],
    "time": "午後"
  },
  {
    "id": "gion",
    "name": "祇園",
    "range": [23, 45],
    "time": "夕暮れ"
  },
  {
    "id": "higashiyama",
    "name": "東山・清水",
    "range": [46, 69],
    "time": "夜"
  },
  {
    "id": "arashiyama",
    "name": "嵐山",
    "range": [70, 89],
    "time": "夜明け前"
  },
  {
    "id": "fox_garden",
    "name": "白狐庭園",
    "range": [90, 90],
    "time": "朝焼け"
  }
]
```

地区はゲームルールではなく、

- 背景
- BGM
- 色調
- 全体マップ
- 地名表示

の切替用。

---

# 6. マス種別

正式に使用する `kind` は以下。

```text
START
NORMAL
COIN
REST
RISK
ITEM
EVENT
GOSHUIN
BYPASS_FORK
BOSS_FORK
BOSS_APPROACH
BOSS
```

## COIN

```json
{
  "kind": "COIN",
  "amount": 2
}
```

着地時のみ発動。

原則:

```text
+2 TRIP COIN
```

---

## REST

```text
HPが最大未満:
  HP +1

HP満タン:
  SKILL +1

HP満タンかつSKILL MAX:
  追加効果なし
```

RESTは着地時のみ発動。

---

## RISK

```text
HP -1
```

RISKガード所持時:

```text
ダメージ0
RISKガード消費
```

---

## ITEM

着地時に既存ランダムITEM取得処理を呼ぶ。

所持上限処理も共通システムを利用する。

---

# 7. メインルート構成

`main_spaces` は必ず90件を明示的に保持する。

NORMAL以外の正式配置は以下。

| 内部No. | 設計No. | 種別 |
|---:|---:|---|
| 1 | 0 | START |
| 5 | 4 | COIN |
| 8 | 7 | REST |
| 10 | 9 | COIN |
| 13 | 12 | RISK |
| 15 | 14 | COIN |
| 17 | 16 | REST |
| 19 | 18 | ITEM |
| 21 | 20 | GOSHUIN / fushimi |
| 22 | 21 | RISK |
| 26 | 25 | ITEM |
| 27 | 26 | REST |
| 30 | 29 | RISK |
| 31 | 30 | EVENT_AUTO |
| 33 | 32 | BYPASS_FORK #1 |
| 35 | 34 | COIN |
| 36 | 35 | RISK |
| 38 | 37 | REST |
| 39 | 38 | ITEM |
| 43 | 42 | COIN |
| 44 | 43 | GOSHUIN / yasaka |
| 47 | 46 | EVENT_CHOICE |
| 50 | 49 | ITEM |
| 52 | 51 | COIN |
| 53 | 52 | RISK |
| 57 | 56 | ITEM |
| 59 | 58 | REST |
| 61 | 60 | RISK |
| 63 | 62 | EVENT_AUTO |
| 64 | 63 | COIN |
| 66 | 65 | ITEM |
| 67 | 66 | RISK |
| 68 | 67 | REST |
| 69 | 68 | GOSHUIN / kiyomizu |
| 71 | 70 | COIN |
| 72 | 71 | BYPASS_FORK #2 |
| 75 | 74 | RISK |
| 77 | 76 | COIN |
| 78 | 77 | ITEM |
| 83 | 82 | RISK |
| 84 | 83 | ITEM |
| 85 | 84 | GOSHUIN / tenryuji |
| 86 | 85 | COIN |
| 87 | 86 | REST |
| 88 | 87 | BOSS_FORK |
| 89 | 88 | BOSS_APPROACH |
| 90 | 89 | BOSS |

それ以外の43マスは `NORMAL`。

正式集計:

```text
NORMAL        43
COIN          10
REST           7
RISK           9
ITEM           8
EVENT          3
GOSHUIN        4
BYPASS_FORK    2
START          1
BOSS_FORK      1
BOSS_APPROACH  1
BOSS           1
----------------
TOTAL         90
```

---

# 8. EVENTデータ

EVENTは3マスのみ。

```text
main:31  自動EVENT
main:47  選択EVENT
main:63  自動EVENT
```

JSON例:

```json
{
  "number": 31,
  "kind": "EVENT",
  "event_id": "kyoto_event_a",
  "event_mode": "auto"
}
```

```json
{
  "number": 47,
  "kind": "EVENT",
  "event_id": "kyoto_event_choice",
  "event_mode": "choice"
}
```

```json
{
  "number": 63,
  "kind": "EVENT",
  "event_id": "kyoto_event_b",
  "event_mode": "auto"
}
```

## EVENT原則

`auto`

- 到着演出
- 効果を自動解決
- プレイヤー選択なし
- 長いモーダルを出さない

`choice`

- 京都通常マップで唯一の二択EVENT
- 明確に価値の違う2択のみ
- COIN / RESTを毎回選ばせる構成にはしない

EVENT具体内容は別データとして後から調整可能にする。

---

# 9. 御朱印仕様

御朱印4種:

```text
fushimi
yasaka
kiyomizu
tenryuji
```

配置:

```text
main:21 fushimi
main:44 yasaka
main:69 kiyomizu
main:85 tenryuji
```

JSON:

```json
{
  "number": 21,
  "kind": "GOSHUIN",
  "goshuin": "fushimi",
  "name": "伏見稲荷"
}
```

## 取得条件

GOSHUINだけは着地判定ではない。

```text
移動pathにGOSHUINマスが含まれた時点で取得
```

つまり、

```text
通過でも取得
着地でも取得
```

一度取得した御朱印は同一周回中に再取得しない。

## 演出

移動中には止めない。

移動終了後に、

```text
御朱印 GET!
伏見稲荷
1 / 4
```

程度の短い演出をまとめて表示。

---

# 10. 近道①

## ID

```text
gion_shortcut
```

## 分岐

```text
main:33
```

## 合流

```text
main:42
```

本線距離:

```text
9
```

近道距離:

```text
5
```

短縮:

```text
4
```

### route

```json
{
  "id": "gion_shortcut",
  "rejoin": "main:42",
  "spaces": [
    {
      "id": "gion_shortcut:S1",
      "kind": "RISK"
    },
    {
      "id": "gion_shortcut:S2",
      "kind": "NORMAL"
    },
    {
      "id": "gion_shortcut:S3",
      "kind": "REST"
    },
    {
      "id": "gion_shortcut:S4",
      "kind": "RISK"
    }
  ]
}
```

ルート距離は、

```text
S1
S2
S3
S4
main:42
```

で5歩。

---

# 11. 近道②

## ID

```text
arashiyama_shortcut
```

## 分岐

```text
main:72
```

## 合流

```text
main:84
```

本線距離:

```text
12
```

近道距離:

```text
6
```

短縮:

```text
6
```

### route

```json
{
  "id": "arashiyama_shortcut",
  "rejoin": "main:84",
  "spaces": [
    {
      "id": "arashiyama_shortcut:S1",
      "kind": "RISK"
    },
    {
      "id": "arashiyama_shortcut:S2",
      "kind": "NORMAL"
    },
    {
      "id": "arashiyama_shortcut:S3",
      "kind": "REST"
    },
    {
      "id": "arashiyama_shortcut:S4",
      "kind": "RISK"
    },
    {
      "id": "arashiyama_shortcut:S5",
      "kind": "RISK"
    }
  ]
}
```

最終的に `main:84` のITEMへ合流する。

したがって近道を選んでも、

```text
main:84 ITEM
```

は取得可能。

---

# 12. branchesデータ

```json
"branches": [
  {
    "id": "gion_shortcut_choice",
    "type": "bypass",
    "choice_space": "main:33",
    "standard_distance": 9,
    "bypass_distance": 5,
    "saved_steps": 4,
    "choices": [
      {
        "id": "main",
        "label": "本線を進む",
        "target": "main:34"
      },
      {
        "id": "shortcut",
        "label": "祇園の裏路地",
        "target": "gion_shortcut:S1"
      }
    ]
  },
  {
    "id": "arashiyama_shortcut_choice",
    "type": "bypass",
    "choice_space": "main:72",
    "standard_distance": 12,
    "bypass_distance": 6,
    "saved_steps": 6,
    "choices": [
      {
        "id": "main",
        "label": "本線を進む",
        "target": "main:73"
      },
      {
        "id": "shortcut",
        "label": "竹林の抜け道",
        "target": "arashiyama_shortcut:S1"
      }
    ]
  }
]
```

## 重要

近道利用にCOIN料金は設定しない。

代償は、

```text
RISK増加
ITEM / COIN取得機会の減少
```

そのもの。

---

# 13. 分岐移動ルール

既存の「残り歩数保持」方式を維持する。

例:

```text
main:31から6を出す
```

移動:

```text
main:32
main:33 ← 分岐
```

ここで一時停止。

残り:

```text
4歩
```

プレイヤーが近道を選んだ場合、

```text
S1
S2
S3
S4
```

まで進む。

次ターンはその位置から継続。

## 重要

分岐を通過するために、

```text
ぴったり停止
```

は要求しない。

---

# 14. ボス選択

最終ボス選択は通常の `branches` に含めない。

トップレベルに、

```json
"boss_choice": {
  "trigger_space_id": "main:88",
  "approach_space_id": "main:89",
  "boss_space_id": "main:90",
  "choices": [
    {
      "id": "direct",
      "name": "白狐決戦",
      "description": "サイコロで直接対決",
      "style": "sugoroku",
      "boss_id": "kyoto_direct_duel"
    },
    {
      "id": "foxfire",
      "name": "狐火六路陣",
      "description": "狐火を読み切る盤面戦",
      "style": "puzzle",
      "boss_id": "white_fox_seal"
    }
  ]
}
```

---

# 15. BOSS_FORK処理

`main:88` へ到達または通過しようとした時点で、

```text
BOSS_CHOICE_REQUIRED
```

へ移行。

選択:

```text
direct
```

または

```text
foxfire
```

を

```gdscript
stage_flags["kyoto_boss_route"]
```

へ保存。

例:

```gdscript
stage_flags["kyoto_boss_route"] = "direct"
```

---

# 16. BOSS_APPROACH

`main:89` はルール効果なし。

ただし見た目を選択ルートで変更する。

```text
direct
→ 白狐の鳥居

foxfire
→ 狐火の鳥居
```

マップ座標そのものを2本に分裂させる必要はない。

**論理ルートは1本、見た目だけ分岐したように見せる。**

これにより、

- セーブ
- カメラ
- 進捗
- 90マス管理

を複雑にしない。

---

# 17. BOSS dispatch

`main:90` 到達時、

```gdscript
stage_flags["kyoto_boss_route"]
```

によって起動ボスを決定。

```text
direct
→ 新ボス

foxfire
→ 現WhiteFoxBattle
```

未設定の場合は安全側として、

```text
direct
```

ではなく、明示的な選択要求へ戻す。

勝手にボスを決定しない。

---

# 18. ボス報酬

両ボスで基本報酬は同一。

```text
京都ステージクリア
ボス勝利扱い
周回進行
ハートルーレット
TRIP COIN両替
CASINO CHIP獲得
```

に差を付けない。

現パズルの方が長いため報酬を増やす、という設計にはしない。

プレイヤーは、

```text
報酬ではなく好きな遊び方
```

でボスを選ぶ。

---

# 19. 御朱印とボス

4御朱印は両ボスに適用する。

意味は共通概念化する。

```text
fushimi
→ 開幕有利

yasaka
→ ボス攻撃開始遅延

kiyomizu
→ 1回のやり直し系効果

tenryuji
→ 1回の出目・行動補正

4種全部
→ 満願ボーナス
```

現ボスでは既存効果を極力維持。

新ボスでは同じ「意味」を別ルールへ翻訳する。

---

# 20. 京都v2 stage_flags

最低限以下を保持する。

```gdscript
stage_flags = {
    "goshuin": {
        "fushimi": false,
        "yasaka": false,
        "kiyomizu": false,
        "tenryuji": false
    },

    "skill_gauge": 0,

    "kyoto_boss_route": "",

    "kyoto_boss_choice_seen": false,

    "kyoto_route_tutorial_seen": false,

    "kyoto_goshuin_tutorial_seen": false
}
```

旧京都固有で不要になった、

```text
completed_loops
巡礼ルート状態
有料近道状態
```

はv2では削除候補。

ただしセーブ移行処理が完了するまでは読み込み互換用に無視して保持してもよい。

---

# 21. セーブ必須項目

京都v2で保存・復元が必要。

```text
current_space_id
lap
hp
max_hp
life
trip_coin
items
skill_gauge
mission
mission_progress
slot_history
goshuin
pending_steps
pending branch
pending EVENT
kyoto_boss_route
boss_choice_pending
score
```

特に、

```text
分岐選択待ち
EVENT選択待ち
ボス選択待ち
```

でアプリ終了しても正常復元できること。

---

# 22. SCORE

SCOREは**累計歩数**として扱う。

COIN、MISSION報酬、余剰COINなどをSCOREへ変換しない。

近道時も、

```text
main番号の差
```

ではなく、

```text
実際に進んだ1ノード = 1歩
```

として累積する。

したがって近道を利用すると、

```text
ゴールまでの実歩数が短い
→ SCORE増加量も少ない
```

という自然な結果になる。

---

# 23. KyotoCourseModel変更

現行の以下の固定検証を廃止する。

```gdscript
branches.size() != 8
```

v2ではJSON側の

```json
"branch_count": 2
```

と照合する。

検証項目:

```text
schema_version == 2
stage_id == kyoto_thousand_year_grid
space_count == 90
main_spaces.size() == 90
main:1 exists
main:90 exists
branches.size() == branch_count
routes.size() == route_count
全next_idが実在
全branch_idが実在
全route rejoinが実在
御朱印IDが4種のみ
boss_choiceが2択
```

---

# 24. KyotoJourney変更

主な変更対象。

## 維持

- `GOSHUIN_IDS`
- 通過pathによる御朱印取得
- `pending_steps`
- 分岐途中復元
- ITEM共通処理
- RISKガード処理

## 変更

- 8分岐前提を撤廃
- 有料近道を撤廃
- EVENT `auto / choice` 対応
- BOSS_FORK専用フェーズ追加
- `kyoto_boss_route` 保存
- BOSS到達時に選択ルートを返却
- 旧巡礼ルート依存処理を削減

---

# 25. 推奨フェーズ追加

```text
PHASE_READY
PHASE_BRANCH
PHASE_EVENT
PHASE_BOSS_CHOICE
PHASE_BOSS
```

ボス選択中:

```gdscript
phase = PHASE_BOSS_CHOICE
```

ROLL不可。

選択完了後:

```gdscript
phase = PHASE_READY
```

残り歩数がある場合はそのまま移動再開。

---

# 26. REST共通仕様

京都独自REST処理を作らず、カイロと共通化する。

正式仕様:

```text
HP不足
→ HP +1

HP満タン
→ SKILL +1

HP満タン & SKILL MAX
→ 追加なし
```

各ステージでREST仕様を分岐させない。

---

# 27. バリデーションテスト

最低限以下を自動テスト。

### データ

```text
main_spaces = 90
NORMAL = 43
COIN = 10
REST = 7
RISK = 9
ITEM = 8
EVENT = 3
GOSHUIN = 4
BYPASS_FORK = 2
```

### 近道①

```text
main:33 → main:42
本線 9歩
近道 5歩
短縮 4歩
```

### 近道②

```text
main:72 → main:84
本線 12歩
近道 6歩
短縮 6歩
```

### 御朱印

```text
main:21
main:44
main:69
main:85
```

を通過しただけでも取得。

### EVENT

```text
自動 2
選択 1
```

### ボス

```text
main:88で選択可能
direct保存可能
foxfire保存可能
main:89で選択状態維持
main:90で正しいボスへdispatch
```

---

# 28. 回帰テスト

以下を壊さない。

```text
ROLL → STOP
SLOT
MISSION
COIN
ITEM
SKILL
HP
LIFE
SCORE
全体マップ
通常7マス表示
セーブ / つづきから
周回
ゲームオーバー
ハートルーレット
CASINO CHIP両替
```

---

# 29. 実装順

## Step 1
`kyoto_thousand_year_grid.json` をschema v2へ更新。

## Step 2
`KyotoCourseModel` の8分岐固定検証を撤廃。

## Step 3
90メインマス＋2近道の移動テスト。

## Step 4
御朱印通過取得を確認。

## Step 5
EVENTを2自動＋1選択へ整理。

## Step 6
REST / ITEM / COIN / RISKを共通仕様へ接続。

## Step 7
BOSS_FORKと `kyoto_boss_route` を実装。

## Step 8
現ボス `foxfire` を接続。

## Step 9
新ボスは仮遷移またはスタブで接続。

## Step 10
カイロ準拠UIへ京都画面を整理。

## Step 11
セーブ・復元・周回テスト。

## Step 12
家族スマホテスト。

---

# 30. 今回まだ実装しないもの

京都v2通常マップ改修と混ぜない。

```text
新ボスの詳細ルール
新ボスの難易度Lv設計
新ボス専用アート
狐火六路陣自体の大改修
御朱印の新ボス内具体効果値
EVENT3種の細かな演出
```

まず、

**京都通常マップをカイロと同じ感覚で気持ちよく1周できる状態**

まで完成させる。

その後、新ボス戦を独立して設計する。