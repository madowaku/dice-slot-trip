# Dice Slot Trip

Godot 4.7で開発中の、目押し型すごろくゲームです。

## ゲームの核

1回のロールで、次の2つを同時に考えます。

- どのマスへ止まりたいか
- 3投目にどの役を作りたいか

旅・ルート・アイテム・ボスは、この判断を支える要素として扱います。

## 現在の正本

- 仕様入口: `docs/PROJECT_BASELINE.md`
- Drive同期仕様: `docs/specs/v1/`
- カイロコース: `data/stages/cairo_stage_v1.yaml`
- ボスレース: `data/bosses/cairo_boss_race_v1.yaml`
- 新規アート受け皿: `assets/art/cairo/v1/`

Driveのv1.0文書とYAMLを確定仕様とします。`00-design-context.md`は検討経緯であり、確定仕様と競合するときはv1.0文書とYAMLを優先します。

## 実装状況

既定起動はv1.0の独立プレイ画面です。3ROLL SLOT、探検猫のピンポイント、58マスのカイロ、分岐・ワープ・ボスゲート、反転ダイス式ボスレースを一連のセッションとして遊べます。

## 起動

```powershell
& 'C:\Dev\Tools\Godot-4.7-stable\Godot_v4.7-stable_win64.exe' --path .
```

## テスト

```powershell
$godot = 'C:\Dev\Tools\Godot-4.7-stable\Godot_v4.7-stable_win64_console.exe'
& $godot --headless --path . --script tests/run_v1_logic_tests.gd
& $godot --headless --path . --script tests/run_v1_play_session_tests.gd
& $godot --headless --path . --script tests/run_v1_stage_model_tests.gd
& $godot --headless --path . --script tests/run_v1_stage_movement_tests.gd
& $godot --headless --path . --script tests/run_v1_play_screen_tests.gd
& $godot --headless --path . --script tools/generate_v1_runtime_data.gd -- --check
```

## 運用ルール

- 新しい仕様は `docs/specs/v1/` を更新する
- 生成物、動画、QAスクリーンショットをリポジトリ直下へ置かない
- 新規カイロ画像は `assets/art/cairo/v1/` の分類に従う
- 旧ランタイムのコードや素材は、v1移行で参照が消えたことを確認してから削除する
