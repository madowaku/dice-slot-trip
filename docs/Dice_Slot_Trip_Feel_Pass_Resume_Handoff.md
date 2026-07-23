# Dice Slot Trip
## Roll-to-Move Feel Pass 再開用ハンドオフ

**目的:** 別のCodex / Antigravityが、現在の未コミット差分を保持したまま、停止地点から安全に作業を再開する。

---

## 1. 現在地点

前担当は以下まで完了している。

- 既存作業差分と指示ファイルを確認
- `hiro-frontend-qa` の手順確認
- 対象4ファイルと既存テストの差分確認
- ヘッドレステストのタイムアウト原因を調査
- `tourism_map_view.gd` のルートモデル参照不足とGodot 4.7型推論エラーを修正
- 静的ロード成功
- 旧19マス仕様を期待していたテスト5件を8マス仕様へ更新
- 出目固定、TurnPhase、ロール世代番号、停止後シーケンスの主要修正を導入
- 再ロードと既存テストを再実行
- 現在の停止点は「曲線部分でタイルが重なるため、ルート中心と矩形を実測して最小限調整する」直前

**重要:** 作業ツリーをリセットしない。既存差分を再実装しない。まず `git diff` と現在のテスト結果を読む。

---

## 2. 最初に行うこと

1. `git status --short` と対象ファイルの `git diff` を保存する。
2. `tourism_map_view.gd` の現在の `route_centers`、`tile_rects()`、表示offset、直径計算を確認する。
3. 静的ロードと、マップ表示に関係するフォーカステストだけを先に実行する。
4. フルテストはレイアウト修正後に実行する。前回の長時間ランナーを無条件に複数起動しない。

---

## 3. タイル重なりの測定

目視で直径を決め打ちせず、8スロットの矩形を実測するデバッグヘルパーを追加する。

### 必須出力

各viewportについて以下を出力する。

- viewportサイズ
- offset `-1..6`
- 各スロット中心座標
- 各スロット直径
- 各矩形
- 重なっているスロットの組
- X/Y方向の重なり量
- 中心間距離

対象viewport:

- `360×640`
- `720×1280`

### 参考ヘルパー

```gdscript
static func overlapping_pairs(rects: Array[Rect2]) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for i in range(rects.size()):
        for j in range(i + 1, rects.size()):
            var a := rects[i]
            var b := rects[j]
            if not a.intersects(b):
                continue
            var intersection := a.intersection(b)
            result.append({
                "a": i,
                "b": j,
                "overlap_x": intersection.size.x,
                "overlap_y": intersection.size.y,
                "center_distance": a.get_center().distance_to(b.get_center()),
            })
    return result
```

矩形は視覚上の安全余白を含め、必要なら `rect.grow(2.0)` でも検証する。

---

## 4. 重なり解消の優先順位

### 第一選択: ルート中心を調整

一部のカーブだけで重なる場合、全タイルを縮小しない。

- カーブ外側へ中心点を数px移動
- U字の対向する腕同士の間隔を広げる
- 前方6マスの読み順を壊さない
- キャラクター、HUD、トレイとの干渉を増やさない

### 第二選択: 路線に沿った等距離サンプリング

ハードコードされた中心点が不均一なら、既存ポリラインの累積距離から8点をサンプリングする。

- 見た目の順序を維持
- 隣接中心間隔をほぼ均等にする
- 分岐と円環では既存専用レイアウトを優先

### 第三選択: 局所サイズ補正

中心調整で解消できない場合のみ、該当スロットを小さくする。

目標下限:

- 現在地: `44px`以上
- 前方1〜3: `40px`以上
- 前方4〜6: `36px`以上
- 直前: `36px`以上

この下限を割る必要がある場合は、タイル縮小ではなくルート中心配置を修正する。

### 禁止

- 一つのカーブのために全タイルを一律で大幅縮小
- 8スロットを再び19スロットへ戻す
- 遠方の丸タイルを復活
- 360×640を未確認のまま720×1280だけで調整

---

## 5. `main.gd` で再確認する重要点

現在の `main.gd` には `TurnPhase`、`roll_sequence_id`、`committed_values`、140/200/140/100msのシーケンスが入っている。再新設しない。

ただし以下を確認・修正する。

### 5.1 実際の移動中フェーズ

現状は `_animate_dice_roll()` の末尾で `TurnPhase.MOVING` にしたあと、`_resolve_roll()` の冒頭で直ちに `TurnPhase.RESOLVING_TILE` へ変わる可能性がある。

**要件:**

- 実際のルートステップアニメーション中は `MOVING`
- 全移動完了後、着地効果を処理する直前に `RESOLVING_TILE`
- `RESOLVING_TILE` のままキャラクター移動を行わない

推奨:

- `_resolve_roll()` 冒頭では `RESOLVING_TILE` にしない
- 移動パス処理開始時に `MOVING`
- `_resolve_landing()` の直前に `RESOLVING_TILE`

ロールトランザクション再開経路も同じ意味になるようにする。

### 5.2 abort後の安全状態

`_abort_map_dice_roll()` は、互換フラグをfalseにするだけでなく、クリーンアップ末尾で安全に `turn_phase = TurnPhase.READY` へ明示遷移する。

ただし、シーン終了中は不要なUI更新を行わない。

### 5.3 確定値の使用

- 停止済みの値は `committed_values` を正とする
- SETTLING以降の役判定、移動距離、SLOT表示へ未確定のプレビュー値を渡さない
- 全ダイス固定後に `committed_values.duplicate()` をロール結果として返す

### 5.4 世代番号

各 `await` 後に `roll_sequence_id` と `is_inside_tree()` を確認する。

- cancel
- scene exit
- boss transition
- rollback

で古いシーケンスを無効化する。

---

## 6. フォーカステスト順序

1. スクリプト静的ロード
2. 8スロットoffsetテスト
3. `tile_rects()` の重なりテスト（360 / 720）
4. 相対ラベル `1..6` と現在地絶対番号
5. TurnPhase入力ロック
6. committed value不変
7. abort後READY
8. 実移動中MOVING、着地解決中RESOLVING_TILE
9. MAP / pause / resume
10. フル `tests/run_tests.gd`
11. validator

テストランナーがタイムアウトした場合は、子プロセスを確認し、同じランナーを重複起動しない。フォーカステストで原因を特定してからフルスイートへ戻る。

---

## 7. 画面QA

以下の同一状態を取得する。

- 通常昼 `360×640`
- 通常昼 `720×1280`
- 分岐 `360×640`
- 円環 `360×640`

確認:

- 8タイルが重ならない
- アイコン、相対番号、現在地番号が重ならない
- 前方1〜6を順番に追える
- 遠方はルート線だけ
- キャラクターが現在地タイルを隠しすぎない
- タイルを縮小しすぎていない

その後、最低10投の短い動画で以下を確認する。

- 出目固定
- SETTLING
- RESULT_LOCK
- SLOT_TRANSFER
- MOVE_PREP
- 実移動中のMOVING

フル30投動画は全テスト通過後に取得する。

---

## 8. 完了条件

- 360×640 / 720×1280で8タイルの重なり0
- 現在地44px以上、前方1〜3が40px以上、前方4〜6が36px以上
- 実移動中のTurnPhaseがMOVING
- 着地効果中がRESOLVING_TILE
- abort後READY
- 停止後の表示値が変化しない
- 既存テスト、新規テスト、validator成功
- 通常、分岐、円環のキャプチャ保存
- 変更ファイルと実測値を完了報告へ記載

---

## 9. 再開用プロンプト

> 現在の未コミット差分を保持し、Roll-to-Move Feel Passの停止地点から再開してください。作業を最初からやり直さないでください。
>
> 既に静的ロードエラー修正、旧19マス期待テスト5件の8マス化、TurnPhase・出目固定・停止後シーケンスの主要修正が入っています。現在の停止点は、曲線部分で8タイルが重なるため、`tourism_map_view.gd` のルート中心と `tile_rects()` を実測して必要最小限調整する工程です。
>
> まずgit diffと現在の実装を確認し、360×640と720×1280で各タイル中心、直径、矩形、重なりペア、重なり量を出力してください。一部カーブだけの問題なら全タイルを縮小せず、ルート中心を調整してください。現在地44px、前方1〜3は40px、前方4〜6は36pxを下限とします。
>
> 併せて `main.gd` を確認し、実際のルート移動中はTurnPhase.MOVING、全移動後の着地効果中だけRESOLVING_TILEとなるようにしてください。abort後は明示的にREADYへ戻し、SETTLING以降はcommitted_valuesを正として出目を変えないでください。
>
> フォーカステスト、フルテスト、validator、360×640 / 720×1280の画面QAの順に進め、未コミットの無関係な差分を巻き戻さないでください。
