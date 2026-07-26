# DICE SLOT TRIP v0.8 製品化・画面統合

## Objective

`feat/card-route-ui` 上の現行 Godot プロトタイプを、まず一投の挙動と情報設計が安定した状態へ戻し、その上でタイトル、ステージ選択、キャラクター選択、結果、図鑑、設定を共通UI文法へ段階的に統合する。最新のローカル設計書、ユーザー指示、Google Docs、既存の選定済みビジュアルと実装を矛盾なく裁定し、Google Play の有料ゲームとして納得感のある製品品質へ進める。

## Goal Kind

`recovery`

## Current Tranche

2026-07-25時点の未コミット `card-route-ui` 差分を保護しながら、最新仕様との適合を読み取り監査する。最初の実行スライスでは、サイコロ上面、停止後ハイライト、3ROLL SLOT転写、1マスジャンプ、着地演出、遅延カメラ追従、入力ゲート、MIX非モーダル進行のうち、証拠上もっとも重要で安全な欠落を一つ選び、実装・自動検証・720×1280/360×640の視覚確認まで完了する。その後、共通UIキットと各画面改修へ継続できるボードを残す。

## Non-Negotiable Constraints

- 作業ブランチは `feat/card-route-ui` に固定する。`main`への切り替え、merge、rebase、resetを行わず、基準 `codex/recovery-from-retreat` を取り込まない。
- HEAD `b559d81` からの既存未コミット6ファイルをユーザー作業として保護し、無関係な差分を巻き戻さない。
- 仕様の優先順位は、現在のユーザー指示、2026-07-25更新のローカルMD、現行の検証済み実装、Google Docs、既存repo docsの順とする。衝突を黙って混在させない。
- `C:/Users/hiro/Desktop/GooglePlay有料級にブラッシュアップしていこう！.md` の上面Quaternion、RESULT_LOCK時だけの着地点強調、MIX非モーダル進行を最新の挙動候補として監査する。
- `C:/Users/hiro/Desktop/各画面UI.md` の共通UIキットと画面順を製品化バックログの正とするが、挙動安定化より先に全面リッチ化しない。
- Google Docsのうち、3ROLL SLOT、探検猫ピンポイント、58マス、周回末鏡面ボス、画像素材監査は参考仕様として採用候補にする。ロール中に現在面へ追従してマスを光らせる旧案は、最新ローカルMDと衝突するため採用しない。
- Godot 4.7、Android 縦持ち 720 x 1280、片手操作、オフライン、中断再開を維持する。
- 通常直線本線では現在地と前方1〜6の計7カードを常時表示し、猫は1マスごとのジャンプだけを使う。着地演出完了後にだけカメラ相当オフセットを追従させ、完了前の次ロールを拒否する。
- 分岐、円環、ボスの既存表示と挙動は、最初の安定化スライスで変更しない。
- 長時間の反復プレイで視線・酔い・入力疲労を増やさず、マップ内ダイス、直線カード列、左3ROLL SLOT、右ROLL、低密度HUDを優先する。
- 製品版UIは汎用アプリ風ダッシュボードにせず、カイロを旅する周回型ダイスアドベンチャー固有の素材感と階層を持たせる。
- 新規ラスター素材は Kenney の利用条件を確認した素材、または ImageGen によるオリジナル素材を使う。出典・プロンプト・加工手順を追跡可能にする。
- キャラクターやアニメーションは承認済みの基準フレームから全ストリップを生成し、共通スケール・共通アンカーで正規化する。
- 画像生成物をUI文字として使わず、読ませる文字と数値は Godot の Control / Label と Noto Sans JP で描画する。
- Figma参照が供給された場合はデザインコンテキストとスクリーンショットの両方を取得してから実装する。参照が無い段階でFigma準拠を装わない。
- 既存の選定済みビジュアルは、その対象画面と状態に限って正確なターゲットとして再利用する。新しい画面や大幅な再構成は、正確な対象画像を解決するまで image-to-code を開始しない。対象が無い場合だけ ImageGen で比較可能な3案を作り、所有者選定後に実装する。
- ImageGenを使う前に既存素材、解像度、透過、ライセンス、使用箇所を監査し、重複生成を避ける。Godotで明確に描ける枠、光、線、数値、UI文字は画像生成しない。
- 各 Worker は許可されたファイルだけを変更し、Godot parse、ロジックテスト、操作スモーク、同一viewportの画面比較を実施する。

## Stop Rule

トランシェ監査が通る、すべての安全なローカル作業がブロックされる、または継続に所有者入力・資格情報・破壊的操作・ボードで決められない戦略判断が必要になった時点で停止する。

計画・調査・Judge選定だけでは停止しない。ただし、正確なvisual targetが存在せず、Product Designの3案から選択する必要が生じた段階では所有者の選択を待つ。

## Canonical Board

Machine truth lives at:

`docs/goals/dice-slot-trip-v06-productization/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-v06-productization/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. この charter と `state.yaml` を読む。
2. active task だけを作業する。
3. Scout / Judge / Worker / PM をタスクの assignee に従って割り当てる。
4. 各タスク完了時に compact receipt を書く。
5. visual target 未選定なら3案を生成して所有者の選択を待つ。
6. 選定後、安全な Worker 範囲が確定したら実装と検証へ進む。
7. 最後に Judge / PM 監査で v0.6 と元の依頼へ照合する。
