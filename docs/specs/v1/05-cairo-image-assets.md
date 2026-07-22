> Source: https://drive.google.com/file/d/13kW5vij2QairyaRi7eiet3oo0uwnzw-g/view
> Status: Normative asset plan
> Synced: 2026-07-22

# Dice Slot Trip
## カイロ画像素材生成リスト v1.0

**対象:** カイロ本線58マス、オアシス環、墓廊の輪、黄金門の鏡面レース、探検猫、3ROLL SLOT、アイテム・スキルドック

---

# 0. 目的

カイロ製品スライスに必要な画像素材を、以下の3種類へ分離する。

1. **ImageGenまたは承認済み基準画像から生成する素材**
2. **Kenney・既存共有アイコン・手描きベクターを優先する素材**
3. **Godotで描画し、画像生成しない素材**

画像を増やすこと自体を目的にせず、通常プレイで長時間見ても疲れず、マス・キャラクター・サイコロの視認性を損なわないことを優先する。

---

# 1. 生成前に監査する既存素材

会話上、すでに存在すると報告されている素材。重複生成を避けるため、実ファイル・解像度・背景透過・使用箇所を最初に確認する。

| ID | 素材 | 報告済み状態 | 監査内容 |
|---|---|---|---|
| EXIST-01 | `explorer-cat-seed-192.png` | 承認済み | 足元アンカー、表示スケール、元SHA-256 |
| EXIST-02 | カイロ昼背景帯 | 実装済み | 市場・ナイル・砂漠・墓都を1枚で賄えるか |
| EXIST-03 | ボス夜景 | 実装済み | 鏡面レース13マスで横方向へ流用可能か |
| EXIST-04 | ランタン | 実装済み | 独立透過素材か、背景へ焼き込み済みか |
| EXIST-05 | 黄金ゲート | 実装済み | ゴール用正面素材として十分か |
| EXIST-06 | 製品アート7点 | 実画面へ接続済み | 7点の名称、用途、重複範囲 |
| EXIST-07 | `item-card.png` | 実装済み | 中央アイコン差し替え可能か |
| EXIST-08 | `skill-card.png` | 実装済み | ピンポイント専用アイコンを載せられるか |
| EXIST-09 | マス種別ピクトグラム | 一部実装済み | ImageGen素材か、共有描画か、Kenney由来か |

**監査結果が不明な素材は、すぐ再生成せず `needs_audit` とする。**

---

# 2. P0 必須生成素材

カイロ1周とボスレースを製品品質で成立させるために必要な最小セット。

## 2.1 探検猫アニメーション

承認済みseedから生成する。生成画像を直接ストリップ化せず、まず基準キーフレームを作り、共通スケール・共通足元アンカーで正規化してからストリップへ組む。

| Asset ID | ファイル案 | 内容 | キーフレーム | 推奨形式 |
|---|---|---|---:|---|
| CAT-01 | `explorer-cat-idle-keys.png` | 通常待機、呼吸、しっぽの弱い揺れ | 4 | 透明PNG |
| CAT-02 | `explorer-cat-hop-keys.png` | しゃがみ、跳び上がり、頂点、落下、着地 | 6 | 透明PNG |
| CAT-03 | `explorer-cat-focus-keys.png` | ピンポイント予約・集中・発動 | 4 | 透明PNG |
| CAT-04 | `explorer-cat-boss-win-keys.png` | ボスレース勝利 | 4 | 透明PNG |
| CAT-05 | `explorer-cat-boss-lose-keys.png` | 悔しいが次周へ進める軽い敗北 | 4 | 透明PNG |

### キャラクター生成条件

- seedの帽子、顔、バックパック、配色を維持
- 正面から少し斜めの既存角度を固定
- 足元アンカーを全フレーム共通化
- 顔の目・鼻・口を崩さない
- 毛並みや装飾を毎フレーム細かく変えない
- 360×640表示で輪郭がちらつかない
- 影はキャラクター画像へ焼き込まず、Godot側で描画

---

## 2.2 砂時計門の番人

戦闘キャラではなく、プレイヤーと並走するレース相手として設計する。

| Asset ID | ファイル案 | 内容 | キーフレーム | 推奨形式 |
|---|---|---|---:|---|
| BOSS-01 | `hourglass-warden-seed.png` | 番人の承認用基準ポーズ | 1 | 透明PNG |
| BOSS-02 | `hourglass-warden-idle-keys.png` | 待機、砂時計の揺れ | 4 | 透明PNG |
| BOSS-03 | `hourglass-warden-move-keys.png` | 並走移動 | 6 | 透明PNG |
| BOSS-04 | `hourglass-warden-win-keys.png` | ボス勝利 | 4 | 透明PNG |
| BOSS-05 | `hourglass-warden-lose-keys.png` | プレイヤー勝利時の反応 | 4 | 透明PNG |

### ボスデザイン条件

- 黒・金・砂色を基調
- 猫とシルエットが混同しない長身形
- 武器を振る戦闘ポーズではなく、門の守護者・走者として見せる
- 黄金門、夜景、ランタンと馴染む
- 小画面でも頭部と砂時計モチーフが判別できる

---

## 2.3 カイロ地区背景

通常時はキャラクターとマスより弱い、低刺激の横長景観帯とする。

| Asset ID | ファイル案 | 地区 | 主な要素 | 推奨ソースサイズ |
|---|---|---|---|---:|
| BG-01 | `cairo-market-day-band.png` | 市場地区 | 日除け布、壺、細い街路、店先 | 1440×640 |
| BG-02 | `cairo-nile-day-band.png` | ナイル河岸 | 川、帆船、ヤシ、遠い街並み | 1440×640 |
| BG-03 | `cairo-desert-day-band.png` | 砂漠街道 | 砂丘、岩陰、遠いピラミッド | 1440×640 |
| BG-04 | `cairo-necropolis-day-band.png` | 墓都・黄金門 | 石柱、墓都、遠い黄金門 | 1440×640 |

### 背景条件

- マスを置く中央帯は低コントラスト
- 人物や小物を中央へ密集させない
- UI文字、番号、看板文字を生成しない
- 左右へスクロール・継ぎ足し可能な構図
- 強い被写界深度、激しい光、細かな砂粒を避ける
- 4地区で水平線・カメラ角度・色温度を統一

---

## 2.4 円環専用の中央情景

円環のタイルはGodotで描画し、中央の情景だけを画像素材として用意する。

| Asset ID | ファイル案 | 内容 | 推奨サイズ |
|---|---|---|---:|
| LOOP-01 | `oasis-loop-center.png` | 水面、ヤシ、小さなオベリスク | 768×768 透明PNG |
| LOOP-02 | `tomb-loop-center.png` | 墓廊の床、石棺、青紫の弱い灯り | 768×768 透明PNG |

条件:

- 円形タイルの外周を邪魔しない
- 中央60%以内へ主要物を収める
- EXIT、現在地、マスアイコンより目立たない
- 発光は弱く、タイル識別を妨げない

---

## 2.5 ボスレース背景

既存夜景が13マス並走レースへ転用できない場合だけ生成する。

| Asset ID | ファイル案 | 内容 | 推奨サイズ |
|---|---|---|---:|
| RACE-01 | `golden-gate-race-night-band.png` | 夜のカイロ、並走2レーン向け横長背景 | 1440×640 |
| RACE-02 | `golden-gate-goal-overlay.png` | 正面の黄金門、ゴール線の背面 | 768×768 透明PNG |
| RACE-03 | `lantern-side-overlay.png` | 左右端用ランタン装飾 | 512×768 透明PNG |

**EXIST-03〜05が要件を満たせば、新規生成しない。**

---

## 2.6 アイテム画像

カード枠は既存を使い、中央のアイテム絵だけを統一生成する。

| Asset ID | ファイル案 | アイテム | 推奨サイズ |
|---|---|---|---:|
| ITEM-01 | `item-water-canteen.png` | 水筒 | 384×384 透明PNG |
| ITEM-02 | `item-compass.png` | 方位磁針 | 384×384 透明PNG |
| ITEM-03 | `item-sand-goggles.png` | 砂よけゴーグル | 384×384 透明PNG |
| ITEM-04 | `item-hourglass-shard.png` | 砂時計の欠片 | 384×384 透明PNG |
| ITEM-05 | `item-golden-scarab.png` | 黄金スカラベ | 384×384 透明PNG |

条件:

- 斜め上から見た同一カメラ角度
- 背景なし、文字なし、枠なし
- 外周に10〜15%の透明余白
- 360×640で主形状が潰れない
- 金属やガラスのハイライト方向を統一

---

## 2.7 探検猫スキル画像

| Asset ID | ファイル案 | 内容 | 推奨サイズ |
|---|---|---|---:|
| SKILL-01 | `skill-pinpoint.png` | 猫の目＋照準＋前方マスの概念 | 384×384 透明PNG |

条件:

- 数字や文字を入れない
- 方位磁針と混同しない
- 「自動命中」ではなく「見やすく狙う」印象
- READY、ARMED、ACTIVE、LOCKEDの状態差はGodot側の枠・色・ゲージで表現

---

# 3. P1 推奨生成素材

ゲームは成立するが、イベントや記録画面の製品感を高める素材。

## 3.1 イベント小画面

フルスクリーン画像ではなく、カード上部へ置く小さな情景イラスト。

| Asset ID | ファイル案 | イベント |
|---|---|---|
| EVT-01 | `event-market-hawker.png` | 市場の呼び込み |
| EVT-02 | `event-ferry.png` | 渡し船 |
| EVT-03 | `event-nile-tailwind.png` | ナイルの追い風 |
| EVT-04 | `event-ruin-whisper.png` | 遺跡のささやき |
| EVT-05 | `event-cat-shrine.png` | 猫像の祠 |
| EVT-06 | `event-golden-gate-prep.png` | 黄金門の支度 |
| EVT-07 | `event-oasis-water-seller.png` | オアシスの水売り |
| EVT-08 | `event-tomb-stele.png` | 墓廊の石碑 |

推奨: 768×432、文字なし、下部を暗くしすぎない。

## 3.2 ステージ選択・記録

| Asset ID | ファイル案 | 内容 |
|---|---|---|
| STAGE-01 | `cairo-stage-key-art.png` | カイロのステージカード用キービジュアル |
| STAGE-02 | `cairo-stage-thumbnail.png` | 小型カード用切り抜き |
| BADGE-01 | `cairo-boss-win-stamp.png` | 番人勝利スタンプ |
| BADGE-02 | `cairo-golden-scarab-album.png` | 図鑑用黄金スカラベ |

タイトル、時間、マス数、BESTなどはGodotのLabelで描画する。

---

# 4. P2 後回しでよい素材

- タイトル画面用の大型カイロキービジュアル
- カイロ専用ロード画面
- 3ROLL SLOTのPAIR / STRAIGHT / TRIPLE大型演出画像
- ボス勝敗の全画面一枚絵
- チュートリアル漫画
- 多数の群衆・商人・帆船アニメ
- 天候差分、夕方差分、砂嵐の全面エフェクト
- 複数衣装の探検猫

PAIR / STRAIGHT / TRIPLEは、まずスロット枠・光・線・粒子をGodotで描画し、画像素材を増やさない。

---

# 5. 画像生成しない素材

以下はImageGenへ出さず、Godot描画、SVG、Kenney、既存共有アイコンを優先する。

| 対象 | 推奨手段 | 理由 |
|---|---|---|
| NORMAL / COIN / REST / RISK / ITEM / EVENT / WARP | 共通ピクトグラム、Kenney、SVG | 小サイズでの一貫性が重要 |
| BOOST / SAND / WIND / GOAL | SVG・Godot描画 | ボスレースで即読性が必要 |
| 相対出目1〜6 | Noto Sans JPまたは数字フォント | ラスター文字は禁止 |
| HUD、TIME、LAP、HP、MAP | Godot Control / Label | 可変情報 |
| 3ROLL SLOT枠 | NinePatch / Godot描画 | 状態変化が多い |
| READY / ROLL / スキル状態 | Button / Label | 多言語・状態管理 |
| ダイス本体 | 既存3D・2.5D描画 | 出目を動的表示するため |
| 楕円影 | Godot描画 | 跳ねる高さと連動するため |
| ルート線、分岐線、円環タイル | Godot描画 | ステージデータに追従するため |
| ハート、ゲージ、コイン数 | 共通UIアイコン＋Label | 状態変化が多い |

マスは外形・中央ピクトグラム・補助色の3層で識別し、昼夜で同じ記号体系を使う。

---

# 6. 最初の生成バッチ

一度に全部生成せず、画面への影響が大きい順に進める。

## Batch 1: キャラクターとボスの基準承認

1. BOSS-01 砂時計門の番人seed
2. CAT-01 idleキーフレーム
3. CAT-02 hopキーフレーム
4. CAT-03 focusキーフレーム

**ここで所有者承認を取る。**

## Batch 2: 背景と円環

1. BG-01〜04
2. LOOP-01〜02
3. 既存ボス夜景の適合監査
4. 必要時のみRACE-01〜03

## Batch 3: アイテムとスキル

1. ITEM-01〜05
2. SKILL-01

## Batch 4: ボスアニメ

1. BOSS-02〜05
2. CAT-04〜05

## Batch 5: イベント・記録

1. EVT-01〜08
2. STAGE-01〜02
3. BADGE-01〜02

---

# 7. フォルダ案

```text
assets/art/cairo/v1/
├─ backgrounds/
│  ├─ cairo-market-day-band.png
│  ├─ cairo-nile-day-band.png
│  ├─ cairo-desert-day-band.png
│  ├─ cairo-necropolis-day-band.png
│  └─ golden-gate-race-night-band.png
├─ loops/
│  ├─ oasis-loop-center.png
│  └─ tomb-loop-center.png
├─ characters/
│  ├─ explorer_cat/
│  │  ├─ seed/
│  │  ├─ keyframes/
│  │  └─ strips/
│  └─ hourglass_warden/
│     ├─ seed/
│     ├─ keyframes/
│     └─ strips/
├─ items/
├─ skills/
├─ events/
├─ stage_select/
├─ badges/
└─ provenance/
   ├─ asset-manifest.yaml
   ├─ prompts/
   └─ hashes/
```

---

# 8. 命名規則

```text
<area>-<subject>-<state>-<variant>-<size>.<ext>
```

例:

```text
cairo-explorer-cat-hop-key03-384.png
cairo-hourglass-warden-idle-key02-384.png
cairo-market-day-band-1440x640.png
cairo-item-compass-384.png
```

- 英小文字
- ハイフン区切り
- 連番は2桁
- `final`, `new`, `latest` は使わない
- 元画像と加工後画像を同名上書きしない

---

# 9. provenance記録

各生成素材につき以下を保存する。

```yaml
asset_id: CAT-02
file: cairo-explorer-cat-hop-key03-384.png
status: approved
source_kind: imagegen
reference_files:
  - explorer-cat-seed-192.png
prompt_file: prompts/CAT-02.txt
generation_id: null
created_at: null
sha256_raw: null
sha256_export: null
edits:
  - transparent_background_cleanup
  - canvas_normalization
anchor:
  x: 0.5
  y: 0.92
scale_group: explorer_cat_v1
license: OpenAI generated asset
reviewed_at_360x640: false
reviewed_at_720x1280: false
```

Kenney素材を使う場合は、パック名、配布ページ、ライセンス、取得日、原ファイル名、加工内容を記録する。

---

# 10. 共通受け入れ基準

## キャラクター

- 共通足元アンカーで位置が跳ねない
- seedから衣装・顔・配色が逸脱しない
- 360×640で顔と帽子が読める
- フレーム間で装備が増減しない
- 背景へ焼き込まれた影がない

## 背景

- マスとキャラクターより弱い
- UI文字や意味のある数字がない
- 地区間でカメラ角度が揃う
- 720×1280と360×640で主要物が不自然に切れない
- 横移動時に継ぎ目が目立ちにくい

## アイテム・スキル

- 透明背景
- 中央1モチーフ
- 文字なし
- 360×640で何の道具か判別できる
- 同一照明・同一角度・同一余白

## 全素材

- 元画像、生成プロンプト、加工履歴、SHA-256を保存
- 画像内のUI文字を最終製品へ使わない
- 同一viewportで実画面比較する
- 無加工原本を残す

---

# 11. P0生成数の目安

| ファミリー | 出力数の目安 |
|---|---:|
| 探検猫キーフレーム | 22 |
| 番人seed・キーフレーム | 19 |
| 地区背景 | 4 |
| 円環中央情景 | 2 |
| ボスレース追加素材 | 0〜3 |
| アイテム | 5 |
| スキル | 1 |
| **合計** | **53〜56枚** |

ただし、アニメーションは一度に全枚生成しない。各ファミリーの最初の1〜2枚を承認してから展開する。

---

# 12. 直近の決定

最初に作るのは以下の4ファミリー。

1. **砂時計門の番人seed**
2. **探検猫のidle / hop / focusキーフレーム**
3. **カイロ4地区の昼背景帯**
4. **水筒・方位磁針・ゴーグル・砂時計の欠片・黄金スカラベ・ピンポイント**

マスタイル、数字、HUD、ダイス、影、ルート線は生成対象から外す。
