# Art asset layout

今回追加したカイロ素材は、実装で直接参照する画像と、生成元・確認用の画像を分けて保管しています。

## 実装用

- `bosses/cairo/` — ボス開始・勝利・惜敗のシーン
- `cards/cairo/discovery/` — 発見カード用の画像
- `events/cairo/` — イベント画像
- `items/cairo/` — アイテム画像
- `memories/cairo/` — カイロの旅の思い出／タイル演出用の景観画像
- `postcards/cairo/` — ステージクリア後の収集ポストカード
- `branding/` — アプリアイコンとストア用フィーチャーグラフィック

実装用の正規ファイル名は、単一の採用版として扱えるよう、生成時の `master`・解像度・`v1` suffix を外しています。差し替え版を併存させる場合は `-v2` などを付けてください。

## 原画・参考資料

- `_source/cairo/` — master、コンタクトシート、可読性確認用画像
- `_source/branding/` — ブランド素材の原画
- `_source/prompts/` — 生成プロンプト
- `concepts/ui/` — UI画面コンセプト。ゲーム実装では直接参照しない
- `_archive/duplicates/` — 重複ファイルの退避先。削除せず保管

`_source`、`_archive`、`concepts` には `.gdignore` を置いているため、Godot の実行用アセットとしては扱われません。新しい画像を実装に採用するときは、正規カテゴリへコピーまたは移動してから参照パスをコードに追加してください。
