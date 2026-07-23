# Android Device QA

UI-P0の最終受け入れは、360／393／412幅に近いAndroid実機で行う。

## 準備

1. Release APKへ正式アイコンとrelease keystoreを設定する。
2. USBデバッグ端末を接続し、`adb devices`で認識を確認する。
3. Debug APKでClassicを保存した後、アプリデータを残したままRelease APKへ更新する。

## フロー

```text
タイトル
→ 旅先選択
→ 旅人カード選択
→ 「この旅人で出発」
→ 初回ロール
→ 通常マップ
→ 砂嵐のキャラバン道
→ 王の迷い環
```

各画面で、縦横サイズとsafe areaを含むスクリーンショットを保存する。

## 合格条件

- Releaseは保存済みClassic値があってもTourismを表示する。
- ReleaseのSceneTreeと画面にDEBUG、Classic切替が存在しない。
- Debugへ戻すとClassic保存値を再利用できる。
- 主要操作は指で確実に押せ、隣接操作を誤タップしない。
- タップ中にPressed状態が見え、連打しても画面遷移は1回だけ。
- ノッチとナビゲーション領域に文字・CTAが入らない。
- 本文、補助文、HUDが通常の閲覧距離で読める。
- 旅先名、能力説明、HUD、モーダルに文字切れがない。
- 初回ロールCTAが片手操作で到達でき、指で出目を隠し続けない。

## 現在の外部ブロッカー

2026-07-17時点のローカル環境には接続Android端末とAVDがない。Release exportは
APK組み立てまで進むが、正式アイコン未設定とrelease keystore未設定で署名工程を
完了しない。コード側のRelease policyは自動QAで検証済み。
