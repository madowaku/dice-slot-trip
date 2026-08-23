# Stage BGM source record

Updated: 2026-08-23

Amazon, Kyoto, and Las Vegas use the following local MP3 files. The source pages are kept
here so the Google Play release can retain an auditable music credit trail.
Before redistribution, verify the current DOVA-SYNDROME license, site terms,
and each creator's conditions on the linked page.

| Stage | Use | Local asset | Source / creator |
| --- | --- | --- | --- |
| Amazon | Stage-select preview | `assets/audio/bgm/amazon/アマゾン探検.mp3` | [アマゾン探検 (DOVA-SYNDROME #7419)](https://dova-s.jp/bgm/detail/7419) — ゆうり (Yuli Audio Craft) |
| Amazon | Normal map | `assets/audio/bgm/amazon/森林ループ_2.mp3` | [森林ループ (DOVA-SYNDROME #4484)](https://dova-s.jp/bgm/detail/4484) — ハヤシユウ |
| Amazon | Boss battle | `assets/audio/bgm/amazon/黒の滝.mp3` | [黒の滝 (DOVA-SYNDROME #14551)](https://dova-s.jp/bgm/detail/14551) — マニーラ |
| Kyoto | Stage-select preview | `assets/audio/bgm/kyoto/古都、路地裏にて.mp3` | [古都、路地裏にて (DOVA-SYNDROME #20469)](https://dova-s.jp/bgm/detail/20469) — 蒲鉾さちこ |
| Kyoto | Normal map | `assets/audio/bgm/kyoto/雅なフィールド.mp3` | [雅なフィールド (DOVA-SYNDROME #14228)](https://dova-s.jp/bgm/detail/14228) — こばっと |
| Kyoto | Boss battle | `assets/audio/bgm/kyoto/お稲荷様.mp3` | [お稲荷様 (DOVA-SYNDROME #23394)](https://dova-s.jp/bgm/detail/23394) — ゆうり (Yuli Audio Craft) |
| Las Vegas | Stage-select preview | `assets/audio/bgm/lasvegas/カジノ.mp3` | [カジノ (DOVA-SYNDROME #17222)](https://dova-s.jp/bgm/detail/17222) — カピバラっ子 |
| Las Vegas | Casino Hub | `assets/audio/bgm/lasvegas/ジャックポット.mp3` | [ジャックポット (DOVA-SYNDROME #18020)](https://dova-s.jp/bgm/detail/18020) — カピバラっ子 |
| Las Vegas | Dice Race | `assets/audio/bgm/lasvegas/ミニマルダービー.mp3` | [ミニマルダービー (DOVA-SYNDROME #15883)](https://dova-s.jp/bgm/detail/15883) — shimtone |

Runtime mapping is defined in `autoload/bgm_manager.gd`:

- stage-select preview: `TRACK_AMAZON_PREVIEW` / `TRACK_KYOTO_PREVIEW`
- normal map: `TRACK_AMAZON_NORMAL` / `TRACK_KYOTO_NORMAL`
- boss battle: `TRACK_AMAZON_BOSS` / `TRACK_KYOTO_BOSS`
- Las Vegas: `TRACK_LASVEGAS_PREVIEW` / `TRACK_LASVEGAS_MAIN` / `TRACK_DICE_RACE`
