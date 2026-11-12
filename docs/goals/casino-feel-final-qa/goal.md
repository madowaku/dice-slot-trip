# CASINO FEEL FINAL QA

## Objective

ラスベガスの6施設を単体と連続ツアーの両方で検証し、旧Raceテストを新しい結果フローへ更新したうえで、HIGH/MEDIUM findingを0件にして `CASINO_FEEL_FINAL_PASS` を判定できる状態にする。

## Goal Kind

`audit`

## Current Tranche

既存Casino回帰の旧Race不一致を整理し、6施設のFeel・テンポ・固有性・結果理解・再挑戦・ナビゲーション・残高・入力安全・レスポンシブUI・音声終了処理を、360x800優先かつ720x1280でも検証する。問題があれば保護対象を変えない最小修正のみ行い、最終Judgeとpushまで完了する。

## Non-Negotiable Constraints

- 確率、BET、pay table、RTP、CasinoBankルール、save format、BGM選曲、HUB施設数、game routeを変更しない。
- Session Aは各施設300 CHIPの独立fixture、Session Bは300 CHIPから6施設を連続し、最後に元セーブを復元する。
- 旧 `run_casino_ui_tests.gd` のRace期待値を正式な rank → WIN/EVEN/LOSS → BET/RETURN/NET → CHIP → 3 CTA へ更新し、通常Casino回帰を0 failuresにする。
- 360x800を最優先し、720x1280も実GPUで確認する。Tween最大scale、teardown、音声残留、二重入力を監査する。
- HIGH/MEDIUM findingはPhase 5G内で解消する。LOWは理由付きバックログでよい。
- 既存の無関係なdirty worktree変更を保存し、Phase 5Gの明示的な対象だけをコミットする。

## Stop Rule

最終Judgeが `CASINO_FEEL_FINAL_PASS` を認め、全Casino回帰0 failures、fixture復元、temporary cleanup、Godot process cleanupを確認した時点で完了する。ゲームデザイン変更、資格情報、破壊的操作、Android実機が必要なら別タスクとして切り離す。

## Canonical Board

Machine truth lives at:

`docs/goals/casino-feel-final-qa/state.yaml`

## Run Command

```text
/goal Follow docs/goals/casino-feel-final-qa/goal.md through CASINO_FEEL_FINAL_PASS. Do not stop after planning unless blocked.
```
