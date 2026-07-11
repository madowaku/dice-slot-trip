# DICE SLOT TRIP

Godot 4.7 / GDScriptで制作中の、縦持ち一人用・世界旅行すごろくです。

## 現在遊べる範囲

- タイトル → カイロ選択 → 3キャラクター選択 → 旅
- 90マスの閉じたPath2Dループ
- 3ダイス、1ダイス、5ダイスから3個選択
- PAIR / STRAIGHT / TRIPLE / ALL ODD / ALL EVEN
- 通常、イベント、アイテム、コイン、ワープ、ショップ、休憩、名所、ボス気配マス
- 周回、旅スタンプ、一行旅メモ、ボス気配
- 自動保存と「つづきから」
- DEBUGからPAIR / STRAIGHT / TRIPLE / ALL ODD / ALL EVEN固定
- ロール中の追加タップで左から1個ずつ早止め。放置時は自動停止

## 起動

PowerShellで次を実行します。

    & 'C:\Dev\Tools\Godot-4.7-stable\Godot_v4.7-stable_win64.exe' --path .

## テスト

    & 'C:\Dev\Tools\Godot-4.7-stable\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd

## M3: ループボス交流

- 通常マスのランダム遭遇、ボス気配マス、未遭遇救済、TRIPLEの確定交流
- 3個体のスフィンクスとの二択交流、交流100%の図鑑登録、次個体と保存復元
- `docs/マス種類と役割表v0.1.md`を基に、盤面へ4つのボス気配マスを追加

イベント30本とアイテム20個のカタログは、M4でデータ駆動の獲得・使用フローとして実装予定です。
