# Amazon + Kyoto integration decisions

Source material: `amazon.zip` and `kyoto.zip`, supplied 2026-08-12.

## Canonical IDs

- Amazon stage: `amazon_suiu_falls`
- Amazon boss: `aquafall` (`aqua_fall` in the course draft was normalized)
- Kyoto stage: `kyoto_thousand_year_grid`
- Kyoto boss: `white_fox_seal`

## Resolved contradictions

- Kyoto's detailed boss implementation spec is authoritative where the overview differs.
- Tenryuji goshuin starts White Fox with Prayer +1. Otowa's Luck water supplies the one-use ±1 shift.
- Mangan (all four goshuin) grants one automatic Foxfire guard, not an extra placed stone.
- White Fox never mutates journey HP directly. A defeat is returned to the journey host, which removes two of the shared three hearts and then resolves the common LIFE rule: HP3 becomes HP1 without spending LIFE; HP1 becomes HP3 while spending one LIFE; HP1 with LIFE0 becomes run-over at HP0.
- White Fox victory is checked immediately after the player action and before Foxfire.
- Cracked seals count toward the 8/8 victory condition.
- Amazon secret-cave entry costs 4 COIN at either supplied entry point.
- Both stages use the shared six-segment Heart Roulette and LIFE/cumulative-score journey contract.

## Generated visual assets

All assets below were generated with the built-in ImageGen tool in the project's established warm 3D storybook-board style. Generated art contains scenery or characters only; gameplay labels, routes, dice values, and HUD are rendered by Godot.

- `assets/art/backgrounds/amazon-suiu-falls-map.png`: portrait jungle waterfall map, rope bridges, ruins, glowing cavern, bottom rainbow.
- `assets/art/city_cards/amazon-city-card.png`: landscape Amazon destination postcard.
- `assets/art/backgrounds/aquafall-waterfall-climb.png`: five-channel vertical waterfall boss arena with dragon shrine.
- `assets/art/bosses/amazon/aquafall-log.png`: transparent moss-covered fallen-log obstacle sprite.
- `assets/art/backgrounds/kyoto-one-day-journey.png`: portrait Kyoto day-cycle route, torii to Gion, Kiyomizu, bamboo dawn.
- `assets/art/backgrounds/white-fox-seal-board.png`: sunrise Kyoto seal-board arena with central 5×5 board.
- `assets/art/bosses/kyoto/white-fox-guardian.png`: transparent white fox guardian character.
- `assets/art/cards/amazon/amazon-item-card.png`: ImageGen item card art for the one-use Forest Canteen HP recovery.
- `assets/art/cards/amazon/amazon-event-card.png`: ImageGen event card art for the river-guide / jungle encounter presentation.

The existing normalized Explorer Cat idle strip is reused using its 192×192 frame and bottom-center-foot anchor metadata.

## Verification contract

- Amazon course: 120 spaces, 15 events, two main branches, secret cave, FLOW transitions.
- Kyoto course: 90 main spaces, eight junctions, four pass-through goshuin, two paid shortcuts, two once-per-lap loops.
- Aquafall: five lanes, reflecting edge movement, maximum one damage per roll, three-roll roles, difficulty every four laps.
- White Fox: eight active seals, 12 turns, predictable clockwise attack, reroll/prayer/offering rules, all goshuin bonuses.

## Amazon audio and Cairo-aligned map shell

- Stage-select Amazon preview plays `assets/audio/bgm/amazon/アマゾン探検.mp3`; Kyoto stage selection preview plays `assets/audio/bgm/kyoto/古都、路地裏にて.mp3`.
- Amazon normal map plays `assets/audio/bgm/amazon/森林ループ_2.mp3` (the supplied `森林ループ` track).
- Aquafall boss plays `assets/audio/bgm/amazon/黒の滝.mp3`; Kyoto normal uses `assets/audio/bgm/kyoto/雅なフィールド.mp3` and White Fox uses `assets/audio/bgm/kyoto/お稲荷様.mp3`.
- Journey normal maps now use the Cairo composition: shared top HUD, compact status band, `3 ROLL SLOT` tray, and item/event/dice action dock. The center remains reserved for the scenic map.
- Amazon item/event buttons open the generated card art with Godot-rendered Japanese copy and one-use item behavior, while landing on a data-driven event opens the same art in the choice modal.

## Cairo-aligned normal-map shell (2026-08-12)

- Amazon and Kyoto now share the Cairo normal-map information hierarchy: dark stage HUD (`旅したマス / BEST / LAP`), coin/HP/progress row, `全体マップ`, parchment stage band, three-cell MISSION band, scenic local map, `現在地 +1〜+6` route preview, message band, three roll slots, round roll button, and four-button tool dock.
- Entering either normal map opens a stage-specific full-map overlay before the first roll. The HUD `全体マップ` button reopens it at any time; closing the intro returns to the local route preview.
- Amazon uses rainforest teal and the supplied waterfall map; Kyoto uses indigo/vermillion accents and its night-city map. Mission copy and route labels are stage-specific while the controls remain familiar.
- Kyoto generated cards are wired at `assets/art/cards/kyoto/kyoto-item-card.png` and `assets/art/cards/kyoto/kyoto-event-card.png`. The item is a one-use `旅守の御朱印` HP recovery and the event preview/choice modal uses the fox-and-lantern card art.
- Kyoto onboarding is shown after the initial full-map sweep. `assets/art/tutorials/kyoto-goshuin-tutorial.png` explains the four goshuin destinations and the automatic `満願の護り` reward; the card is acknowledged once per saved journey via `kyoto_goshuin_tutorial_seen`.
- Goshuin checkpoints are pass-through rewards: entering a chosen pilgrimage route and crossing its shrine checkpoint immediately records the stamp before the route rejoins main. The traveler pauses for a short red seal “pop” with location-specific copy (for example, `伏見稲荷 御朱印をいただいた！`); checkpoint markers are larger than ordinary Kyoto tiles so the goal reads as a shrine checkpoint rather than a normal stop.

## Shared cockpit proportions (2026-08-13)

- Amazon and Kyoto normal play now reserve roughly 44–47% of the 720×1280 viewport for the local map and roughly 27% for the message, roll tray, and four-button tool dock. This follows the Cairo cockpit while retaining a slightly taller scenic window.
- The shared HUD, stage band, MISSION band, message band, roll tray, and tool dock use fixed cross-stage heights. Only the map content and stage palette change.
- The full portrait background remains intact for the opening sweep and full-map overlay. During normal play an `AtlasTexture` crops a shorter camera window around the current route position; the camera follows after the animated landing effect.
- The three-slot luxury frame and round roll control are restored to Cairo-scale prominence. Item/event duplication inside the tray was removed so the permanent `ITEM / COIN / SKILL / MENU` dock remains the single shared tool row.

## Mobile product UI pass (2026-08-13)

- The 720×1280 HUD now uses larger labels and values plus Cairo's survival readout: a 32px Explorer Cat icon with `×LIFE`, followed by exactly three filled/empty hearts (`♥/♡`). Amazon and Kyoto use fixed HP3/LIFE3; RISK removes one heart and reaching HP0 spends one LIFE and immediately refills all three hearts. Legacy HP6 journey saves migrate by clamping to HP3.
- Normal and full-map route markers use a shared semantic color system (normal, coin, event, rest, risk, special) with a white pictogram inside a bordered color medal. The next six spaces now show their actual upcoming types, giving the player useful planning information before rolling.
- Boss destinations now use a shared wine-and-gold crown emblem (`scripts/ui/boss_map_emblem.gd`) instead of the ordinary item pouch icon. The emblem is larger, ringed, and labeled `BOSS`; Cairo's gold guardian gate receives the same crown badge above its landmark, while Amazon and Kyoto use it on the local map, full-map overview, and seven-space route strip.
- A compact high-contrast 3D die is restored above the `現在地〜+6` strip. Rolling animates and plays the shared roll/landing SE; the round action contains the antique ivory-and-brass die illustration.
- The normal-map 3D die is docked to the lower-right on both Amazon and Kyoto, keeping the scenic center readable while giving the primary turn control one consistent touch location.
- The luxury three-window slot tray is Cairo-scale, and each 34px result is centered against its painted window. The menu exposes BGM volume, SE volume, travel encyclopedia, continue, and return to stage selection; settings persist on every exit path.
- The opening full-map presentation performs a slow top-to-bottom zoom/pan and settles to the complete course. It remains closable throughout so repeat players are never forced to wait.
- Normal-play map cameras show the traveler neighborhood (Amazon 13% / Kyoto 12% of the portrait course height). Amazon keeps the traveler high in frame so roughly ten upcoming spaces remain visible; its 36px markers and right-offset die prevent overlaps. Edge markers are culled, and the separate `現在地〜+6` strip remains the authoritative exact forecast.
- Kyoto keeps the traveler around 66% down the normal-map viewport. Because its route advances upward through the portrait, this reserves roughly twice as much camera space for upcoming checkpoints as for already-passed spaces while leaving the bottom route strip clear.
- The persistent roll tray drops the redundant `直近3回の出目` heading and reinvests that space in play: the luxury slot frame fills 456×208px, result copy grows to 42px, and the circular roll target grows to 192px with a 108px antique die illustration.
- Kyoto's Fox Fire Six Routes boss uses the same fixed three-heart display contract (`♥♥♥ 3/3` at full health). Legacy saves that stored HP6 are migration input only and are clamped to HP3 at the journey boundary. A full-health boss victory uses Cairo's `PERFECT! / HP FULL` continuation, while only wounded victories open the six-segment recovery roulette.

## Cairo-aligned normal-map motion (2026-08-13)

- Amazon and Kyoto use the same two-tap die rhythm as Cairo: the first tap starts a readable 3D face carousel, the second tap locks the currently visible face, and the locked face is copied into the next slot window.
- After STOP, the route model resolves the die distance but the presentation walks the returned path one space at a time. The Explorer Cat uses a short, low-stimulation arc per space, pauses on the destination for a tile-kind landing pulse, then eases the portrait AtlasTexture camera to the new route window.
- Branches use the same path animation both before the choice modal and after the selected branch, so a detour never teleports the traveler without feedback. Event, secret, risk, rest, coin, and boss landing copy remains in the permanent message band until the next action owns it.
- If Amazon's die lands exactly on a junction, the route choice still opens immediately and reserves one visible hop into the selected route. This keeps both choices actionable instead of passing a zero-step movement to the course model.
- The local 3D map die is a 128px control (with high-contrast pips), kept above the `現在地〜+6` strip. The bottom Cairo-style round action remains the touch target and changes its cue from `振る` to `止める` while the carousel is live.

## Stage-specific onboarding and travel resources (2026-08-13)

- Amazon's first landing on a blue FLOW tile pauses before movement and opens `assets/art/tutorials/amazon-flow-tutorial.png`. Dismissing it continues the animated water transfer; later FLOW landings use the compact `急流マス` landing cue only.
- Kyoto's first junction pauses before the route-choice modal and opens `assets/art/tutorials/kyoto-route-tutorial.png`, explaining that a main road choice can move the traveler to a detour or shortcut. The seen flag is stored in the journey snapshot.
- The shared bottom dock now reads live journey resources: item inventory `0/3…3/3`, current COIN count, and the Cairo skill gauge. PAIR charges +1, STRAIGHT +2, and TRIPLE fills the gauge; READY lets the player choose the next die face from 1–6. Items are lap-local and future ITEM spaces can award up to three.
- The first READY state opens a Cairo-style discovery card with a single tap-to-dismiss action. Dismissing the card never arms or consumes the skill; the player can keep rolling and open the READY skill button later when the pinpoint face is useful.

## ITEM spaces and Cairo item set (2026-08-14)

- Amazon's 12 requested numbered spaces are ITEM spaces: `2, 10, 27, 34, 45, 51, 56, 59, 78, 90, 99, 110`. The numbers are the authored course numbers, so branch spaces retain their route IDs (`canopy:27`, `stream:45`, and so on) instead of being duplicated onto the main spine.
- Kyoto's main-line spaces `18, 28, 43, 63, 75, 88` are ITEM spaces. The `gion_loop:L4` and `stone_garden:R4` loop exits are also ITEM spaces before rejoining main 39 and 62; these eight detour pickups are outside the 90-space main count.
- Both stages share Cairo's three-item catalog: `旅人の水筒` (HP +1), `真鍮のコンパス` (the next die movement +1), and `スカラベの護符` (negates the next RISK). Each ITEM landing grants one random item. A full three-item bag converts the pickup to COIN +2, matching Cairo's overflow rule.
- The permanent ITEM card opens the live inventory and offers one touch-sized action per owned item. Items are consumed only while READY; the compass and scarab remain visible through the HUD flow until their next movement/RISK consumes them.

## Event and overview source-of-truth (2026-08-13)

- Amazon follows the shared event rule in `Dice_Slot_Trip_仕様書.md` and the supplied `Codex実装指示書：Amazon EVENTカード15種の選択肢実装.md`: event copy is short and every one of its 15 authored cards now presents exactly two choices. The event modal creates one clearly separated button per data choice; effects are applied only after a choice, with paid choices disabled when COIN is insufficient.
- Event movement is data-driven: ordinary `move_to` choices do not trigger the destination tile, while No.52 explicitly triggers the 54→58 FLOW/EVENT chain and No.71 explicitly opens the main:74 two-route branch. Those extra hops are returned in the event path so the cat animation shows the complete transfer.
- Kyoto's full-map overview is based on the stage course JSON rather than a decorative main-line approximation: 90 main spaces plus 38 spaces across eight detours (128 route spaces total). The overview draws the main spine and each branch/loop from its junction entry to its documented rejoin, and uses a portrait viewport matching `assets/art/backgrounds/kyoto-one-day-journey.png` so the Fushimi torii-to-Arashiyama route is not cropped. The normal camera uses the same annotated main-route waypoints, so local markers follow the painted path instead of the old ten-column fallback grid.

## Route readability pass (2026-08-15)

- Both normal maps now draw gold connectors for the main road/low-risk primary branch and stage-accent connectors for detours/high-risk branch legs. A compact `道しるべ` legend is present in the local map and opening full-map view, so the player can identify the route class before opening a junction.
- Every branch choice previews its projected stop using the current remaining die distance: the choice card shows `本線` or `脇道`, the destination tile type (`RISK`, `COIN`, `REST`, etc.), the readable space name, and the number of spaces until the stop. Internal route IDs are intentionally hidden from player-facing copy. Amazon's two alternate route groups use the lower-risk option as the visually designated main-side choice; Kyoto follows its explicit `main`/detour targets.
- Full-map ordinary footprints are reduced to a small route texture while semantic checkpoints keep larger colored medals. Short Kyoto loops (`gion_loop` and `stone_garden`) receive a small vertical spread and collision-aware marker nudge so their four checkpoints remain individually visible instead of stacking at one main-road y-coordinate.
- Kyoto's longer detours and shortcuts preserve the main route's upward travel direction and expand their interpolated lane around the entry/rejoin midpoint. This prevents the left-side pilgrimage legs from appearing to run backwards and keeps the right-side three-space shortcuts from collapsing into overlapping markers.

## Stage MISSION counters (2026-08-15)

- The supplied generic layout/spec documents define the MISSION band but do not define an Amazon/Kyoto counter owner. Amazon's separate stage-data spec does define a broader `DISCOVERY` metric (`discovered_space_ids`, for example `73/120`); that is an exploration log, not the compact five-step HUD mission. The existing stage copy (`発見 0/5`, `灯籠 0/5`) is therefore treated as the intended contract here: Amazon `発見` counts landings on EVENT spaces, and Kyoto `灯籠` counts landings on REST spaces.
- Counters advance on the resolved landing (not when merely passing through a space), clamp at 5/5, persist in the journey snapshot, and reset with the other lap-local resources at the start of the next lap.

## BGM provenance (2026-08-15)

- The six Amazon/Kyoto tracks and their DOVA-SYNDROME source pages are recorded in [`docs/bgm_sources.md`](../bgm_sources.md). Runtime file-to-phase mapping remains centralized in `autoload/bgm_manager.gd`.
