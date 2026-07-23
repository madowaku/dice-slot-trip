# T002 — v0.6 製品化順序の裁定

## Decision

1. T003で3つのvisual targetを先に作る。
2. T003完了後、所有者へ選択を依頼する。選択待ちは純粋domain modelを止めない。
3. 新規v0.6 roll-set domain Worker（T003A）をT005より前に実行する。
4. T005のmain UI統合はvisual target選定かつT003A検証完了まで禁止する。

## Product / Legacy Boundary

- 製品版ではv0.6へ置換する。旧90マスは恒久的な互換モードにしない。
- 移行中のみ明示的なlegacy/debug入口として隔離保持できるが、release exportから到達不能にする。
- 初期基準は本線32マス。開始マスと周回末boss gateを含み、表示分母も32。
- 8マス円環とバイパス固有マスは32へ加算しない。入口・復帰先は本線側だけで数える。
- 将来v11でruleset/profile/runを分離する。v10途中ランを32マスへ位置変換しない。
- 音量・表示設定など同義のprofileだけ移送し、v10 runは読み取り専用legacy archiveとして保持する。

## T003 Visual Targets

すべて720 x 1280、同じ状態を示す。

- カイロ、第4周
- HP 2/3
- 自己ベスト比 -2.4秒
- 本線進行 18/32
- ネコが8マス円環内、EXITまで4
- 3投slot `[6][6][_]`、次が3投目
- 固定下部トレイに1個のダイスがREADY
- 本線、分岐、バイパス、円環、boss gateが判別可能

Directions:

- A `Sunlit Cairo Diorama`: 旅情優先。陽光、砂岩、市場、オアシスの小型2.5Dジオラマ。羊皮紙・真鍮・ターコイズ。
- B `Explorer's Atlas`: 可読性優先。旅行地図、手描き製図、切手。経路と停止判断を最優先。
- C `Lantern Night Bazaar`: 目押しと三投リズム優先。夕暮れ市場、藍色、銅、ランタン、革と木のトレイ。

色替えではなく、地図の空間表現、HUD階層、トレイ素材を変える。画像生成文字を最終UI文字として使わない。汎用dashboard、過剰なカード、90マス、同時複数ダイスは禁止。

## T003A Contract

- 1〜6を1投ずつ3枠へ蓄積。
- 1投目・2投目は役を返さない。
- 3投目だけNONE / PAIR / TRIPLEを判定。TRIPLE優先、PAIRはexactly two、STRAIGHTなし。
- 完成時に自動消去せずsnapshotを読める。`reset_after_resolution` だけが空にする。
- 1〜6以外、4投目、未完成評価、二重resetを決定的に扱う。
- UI、報酬、移動、save migrationを扱わない。

## Deferred

- visual target未選定またはT003A未検証のT005。
- dirty `main.gd` / GameState / board viewsへの統合。
- v11 save、旧90マス削除、新course model。
