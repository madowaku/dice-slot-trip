# T001: Phase B Evidence Map

Task: `T001`
Kind: `scout`
Status: `current`

## Summary

DICE TOWERのBET10正期待値は、`roundi`で11.5→12、15.5→16、32.5→33となる半CHIP切上げを最適方策が選択的に回収することが原因。ルールを変えず倍率を`1.10 / 1.25 / 1.50 / 1.80 / 2.00 / 2.30 / 2.70 / 3.10 / 3.60 / 4.20`へ変更すると、BET10/20/50すべての最適RTPが97.84%になり、合理的な最初の回収地点が1Fから4Fへ移る。

## Tower Evidence

- Model: `scripts/game/dice_tower_model.gd:3-73`
- DP: `tools/audit_las_vegas_economy.py:46-59`
- State value: `V_b(f)=max(round(b*m_f), [4*V_b(f+1)+V_b(min(10,f+2))]/6)`。STARTではROLL固定。
- Current optimal:
  - BET10 102.796%、回収1/3/5/8/9F、BUST約20.04%。
  - BET20 98.920%、回収1/5/9F、BUST約23.64%。
  - BET50 99.254%、回収3/5/9F、BUST約40.30%。
- Candidate A 全倍率×0.96: 95.291 / 95.602 / 95.008%。小数が不自然。
- Candidate B 丸め意識段階調整: 98.152 / 95.802 / 96.257%。BET10だけ約2.35pt有利。
- Candidate C 4F誘惑曲線: 97.840 / 97.840 / 97.840%。1F回収94.17–95.00%、3F96.11%、4F97.84%、5F94.11%、完走90.96%。推奨。

## Six-Facility UX Evidence

- RACE: `scripts/app/dice_race_screen.gd`。感情役割は「狙った目で推しを追い上げたいとき」。RETURNを獲得/+表示してNETと混同、旧`×4`文言が残る。
- TOWER: `scripts/app/dice_tower_screen.gd`。感情役割は「あと1段だけ欲張りたいとき」。初見理解は強いが成功時は専用結果カードを使わずRETURN/NETが曖昧。
- ROULETTE: `scripts/app/dice_roulette_screen.gd`。感情役割は「考え込まず派手な一発に賭けたいとき」。BET/RETURN/NETは既に明快。
- TREASURE: `scripts/app/treasure_21_screen.gd:181-213,597-632`。感情役割は「危険な次の一目を読んで止め時を決めたいとき」。setup配当表がPhase A以前の値でモデルと不一致。
- POKER: `scripts/app/dice_poker_screen.gd`。感情役割は「役の伸びしろを考えてダイスを残したいとき」。BET/RETURN/NETは既に明快。
- VAULT: `scripts/app/vault_break_screen.gd`。感情役割は「同じ出目をどの鍵穴へ置くか悩みたいとき」。勝利の+rewardがRETURNを純増に見せ、複数候補時の価値差説明が弱い。
- HUB: `scripts/app/casino_hub_screen.gd`。subtitleはtooltipだけで、タッチ画面では施設名+PLAYしか見えず、遊び分けが選択前に伝わらない。

CTAは即再debitとsetup復帰を分けるべき。即再戦だけ`PLAY AGAIN`、設定へ戻る操作は`CHANGE BET`または`NEW GAME`系とし、固有操作ROLL/STOP/SPIN/DEALは維持する。

## Vault Lifetime

- `data/casino/vault_break_templates.json`: 30問（BRONZE 8 / SILVER 8 / GOLD 8 / BLACK 6）。
- `scripts/game/vault_break/vault_break_selector.gd`: 直近2問を除外し、同structureの連続も制限。同一templateの最短再登場は3ゲーム後。
- 熟練RTP: BRONZE平均88.706%、SILVER88.407%、GOLD89.430%（最大93.120%）、BLACK87.010%。記憶攻略でも100%未満なので経済修正不要。

## Capture And Verification

- `project.godot`: logical 720×1280、physical override 360×800。
- Existing recorders: `tests/record_las_vegas_casino_expansion.gd`, `tests/record_dice_race.gd`, `tests/record_dice_tower.gd`。
- UX証拠は非headlessでactual renderingを確認する。既存expansion recorderにはTREASURE/VAULT結果、TOWER成功結果がないため、Phase Bでbounded capture hook補完が必要。

## Dirty Boundary

Baseline HEAD `1c01a24`。APK idsig、import群、音声、`export_presets.cfg`、`art_source/bgm_original_before_phase4b/`、`tests/run_high_low_tests.gd.uid`はユーザー所有として除外。ScoutのPython importが`tools/__pycache__/audit_las_vegas_economy.cpython-314.pyc`を生成したため、commit対象外の一時生成物としてPMが安全削除する。

## Ranked Candidates

P1: TOWER 4F曲線、TREASURE配当表示同期、RACE/TOWER/VAULTのRETURN/NET分離、TOWER成功結果カード。

Small P2: HUB感情役割1行、VAULT複数候補の短い判断ヒント、TREASURE初回GOLDEN返却額、CTA意味統一。

Deferred: 大規模アセット、RACE cash-out復活、POKERルール変更、メタ巡回報酬。
