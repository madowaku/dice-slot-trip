# TOURMAP-03A マップ上1ダイス往復

## Outcome

Tourism Map表示中の1ダイスロールを、下部トレイから観光マップ上のLanding Zoneへ投射し、既存早止め／自動停止で確定、到達先を短く強調してトレイへ帰還する一続きの体験にする。

## Non-negotiables

- 対象ブランチは `feat/tourmap-dice-overlay`。
- Tourismかつ1ダイス時だけMap presentationを使い、Classicは既存トレイ演出を完全維持する。
- 出目、早止め、役、移動、報酬の唯一の正解は既存ロジックとする。
- 3Dダイスをreparentせず、既存mesh、面姿勢、収束、SE、固定出目を再利用する。
- 現在地、到達可能数字、危険、名所、景観中心をLanding Zoneで隠さない。
- 2／3／5ダイス、FLOW、地区別zone、完全物理、カメラ全面改修は対象外。
- 中断時は未確定ならrollback、確定後なら再commitせず結果保持から再開できる境界を設ける。

## Required experience

`TRAY_IDLE → LAUNCHING_TO_MAP → ROLLING_ON_MAP → STOPPING → RESULT_HOLD → RETURNING_TO_TRAY → COMPLETE`

- 往路は引き、山なり投射、小さな跳ね、転がりを含む。
- 早止めは最初の有効入力だけを受け付ける。
- 結果保持は0.35〜0.55秒、到達先を0.3〜0.6秒強調する。
- 復路は浮き、縮小、緩い弧で旅道具へ収まる。
- 全往復は自動停止込みで約2秒を目標にする。

## Acceptance

- Tourism 1-dieは地図上、Classicは既存トレイ内でロールする。
- 出目とゲーム結果が一致し、commitは一度だけ。
- launch/roll/contact/land/lock音と早止めが既存どおり同期する。
- 到達先強調だけではCLEANや着地効果を変更しない。
- 帰還後に二重表示、残像、3D node、audio voiceが残らない。
- ロール中のマップ、アイテム、スキル、DEBUG、View切替入力を遮断する。
- 20回連続、90→01、360×640、safe-area契約、既存回帰がPASSする。
