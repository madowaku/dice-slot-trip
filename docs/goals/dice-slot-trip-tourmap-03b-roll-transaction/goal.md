# TOURMAP-03B 永続ロールトランザクション

## Outcome

ロール結果、移動、着地効果、ターン解決を段階的かつ冪等に保存し、アプリ終了後も報酬や交流を失わず、二重適用せずに旅を再開できるようにする。

## Non-negotiables

- 正本は既存ゲームロジックであり、Canvas座標、回転角、Tween進行率を保存しない。
- `PRE_ROLL → ROLLING → RESULT_COMMITTED → MOVEMENT_COMMITTED → SPACE_EFFECT_COMMITTED → TURN_RESOLVED` の順序を守る。
- `PRE_ROLL / ROLLING` は未確定としてロール前へ戻す。
- 確定済み結果は出目を再表示し、完了済みの移動・報酬・交流を再適用しない。
- EVENTからのボスhandoff、100%交流、図鑑登録、次個体生成を中断しても別イベントや別交流を再抽選しない。
- 旧セーブv6、Classic表示、03A Canvas 2.5D、M3、M4A、CLEAN、RISK、LAP、LANDMARKを維持する。
- ユーザー追加の未追跡仕様書と画像は変更・収録しない。

## Acceptance

- 各phaseが保存復元され、逆行・二重commitが拒否される。
- RESULT_COMMITTED復帰で確定出目を短く確認してから移動する。
- EVENT→ボスhandoff消費直後と100%登録直後の中断が冪等に復帰する。
- 通常COIN着地、90→01、旧セーブ移行がPASSする。
- 全自動テスト、実ゲーム復帰QA、既存回帰、Goal checker、Judge監査がPASSする。
