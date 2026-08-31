# Stage BGM source record

Updated: 2026-08-31

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
| Las Vegas | Global stage selection | `assets/audio/bgm/lasvegas/ドキドキ賭けごと.mp3` | [ドキドキ賭けごと (DOVA-SYNDROME #21985)](https://dova-s.jp/bgm/detail/21985) — 香居 |
| Las Vegas | Las Vegas selection preview | `assets/audio/bgm/lasvegas/カジノ.mp3` | [カジノ (DOVA-SYNDROME #17222)](https://dova-s.jp/bgm/detail/17222) — カピバラっ子 |
| Las Vegas | Casino Hub | `assets/audio/bgm/lasvegas/ジャックポット.mp3` | [ジャックポット (DOVA-SYNDROME #18020)](https://dova-s.jp/bgm/detail/18020) — カピバラっ子 |
| Las Vegas | Dice Race | `assets/audio/bgm/lasvegas/ミニマルダービー.mp3` | [ミニマルダービー (DOVA-SYNDROME #15883)](https://dova-s.jp/bgm/detail/15883) — shimtone |
| Las Vegas | Dice Roulette | `assets/audio/bgm/lasvegas/ルーレット.mp3` | [ルーレット (DOVA-SYNDROME #8634)](https://dova-s.jp/bgm/detail/8634) — Phalene |
| Las Vegas | TREASURE 21 | `assets/audio/bgm/lasvegas/ShotGlass.mp3` | [ShotGlass (DOVA-SYNDROME #737)](https://dova-s.jp/bgm/detail/737) — Merry bad ending |
| Las Vegas | DICE POKER | `assets/audio/bgm/lasvegas/Dark blue night.mp3` | [Dark blue night (DOVA-SYNDROME #23442)](https://dova-s.jp/bgm/detail/23442) — 蒲鉾さちこ — Track 1 |
| Las Vegas | DICE TOWER | `assets/audio/bgm/lasvegas/Rain Soaked Friday.mp3` | [Rain Soaked Friday (DOVA-SYNDROME #23792)](https://dova-s.jp/bgm/detail/23792/track/3) — MFP〖Marron Fields Production〗 — Track 3 loop short |
| Las Vegas | VAULT BREAK | `assets/audio/bgm/lasvegas/忍び足.mp3` | [忍び足 (DOVA-SYNDROME #15786)](https://dova-s.jp/bgm/detail/15786) — 田中芳典 |

Runtime mapping is defined in `autoload/bgm_manager.gd`:

- stage-select preview: `TRACK_AMAZON_PREVIEW` / `TRACK_KYOTO_PREVIEW`
- normal map: `TRACK_AMAZON_NORMAL` / `TRACK_KYOTO_NORMAL`
- boss battle: `TRACK_AMAZON_BOSS` / `TRACK_KYOTO_BOSS`
- Las Vegas: `TRACK_STAGE_SELECT` / `TRACK_LASVEGAS_PREVIEW` / `TRACK_LASVEGAS_MAIN` /
  `TRACK_DICE_RACE` / `TRACK_DICE_ROULETTE` / `TRACK_TREASURE_21` / `TRACK_DICE_POKER` /
  `TRACK_DICE_TOWER` / `TRACK_VAULT_BREAK`

The DOVA-SYNDROME page identifies this as the 1:40 BGM “ルーレット” by Phalene.
`Dark blue night` uses the page's Track 1 (the electric-piano version), while
`Rain Soaked Friday` uses the user-selected Track 3 loop-short download.

## Integrity record

SHA-256 values are for the local MP3 bytes admitted to the project on 2026-08-31.

| Local asset | SHA-256 |
| --- | --- |
| `ドキドキ賭けごと.mp3` | `86FD90C863EC7730ACAD7555AB03C9663BC64E067C22A8617E02DCE36669544F` |
| `カジノ.mp3` | `626B16753A7F0BD3FD3DB8697C1AFE317F29BED0EE815EEBC92EAAE9DD9E1801` |
| `ジャックポット.mp3` | `DF3F1039C0A998414167FFD1B3AD4EE0DCF1E3DD919ACBA02AAA1E0A5033DFDC` |
| `ミニマルダービー.mp3` | `BA98E6E6C15CF60BFC9AC44FE2D22FDFEDFE35F9F70C83B1E4AF74D9C555B25E` |
| `ルーレット.mp3` | `2B4DCEBBC958BFACED98F00095F06DA0DCDCDAD04240F92ACD289CEC5C22ACA0` |
| `ShotGlass.mp3` | `6852CEFC2EFF42FBC140DA2DE4E1DD2199F4D270B6218EF73048475E8EF26952` |
| `Dark blue night.mp3` | `DA6AB38082ADFAD3B8B403087DD1ED291C32A218520FF417417632FEA9C4B810` |
| `Rain Soaked Friday.mp3` | `1D432246E7CDEB11840CF72834944E1DA46E17185710F3F0B4436256AB56610E` |
| `忍び足.mp3` | `18E5C4A8D12DB8D202B8A8AFF1F059A12BA78A76BBC6925FDF8EA640DD0B21E1` |

The DOVA license permits game and app background-music use under its terms, but
the same page asks users to consult the operator before embedding audio into a
tool or platform. Reconfirm the linked license, site terms, and each creator's
conditions before any public Android distribution.
