# T007 — v0.6 Cairo Course Contract

## Decision

44-node standalone graphとして実装する。本線32、バイパス固有4、独立円環8。`BOSS_GATE` は終端で暗黙周回しない。旧 `BoardModel` は変更しない。

## Main Route

`main`, index `0..31`:

```text
00 START
01 NORMAL
02 COIN
03 NORMAL
04 EVENT
05 ITEM
06 NORMAL
07 REST
08 COIN
09 NORMAL
10 EVENT
11 ITEM
12 BYPASS_FORK
13 COIN
14 ITEM
15 NORMAL
16 REST
17 COIN
18 ITEM
19 NORMAL
20 NORMAL
21 RISK
22 LOOP_PORTAL
23 NORMAL
24 COIN
25 EVENT
26 ITEM
27 NORMAL
28 REST
29 RISK
30 NORMAL
31 BOSS_GATE
```

本線分母は32。STARTとBOSS_GATEを含み、バイパス・円環固有マスは含めない。

## Bypass

`bypass_sirocco`:

- choice point: `main:12`
- spaces 0..3: `[RISK, NORMAL, RISK, NORMAL]`
- rejoin: `main:20`
- standard distance: 8 steps through `13..20`
- bypass distance: 5 steps through four unique spaces then `main:20`
- advantage: exactly 3 steps
- standard `13..19` has five preparation opportunities: COIN 13/17, ITEM 14/18, REST 16
- bypass has zero COIN/ITEM/REST and exactly two RISK

## Loop

`loop_souk_ring`:

```text
0 LOOP_ENTRY
1 COIN
2 RISK
3 ITEM
4 EXIT_GATE
5 COIN
6 RISK
7 ITEM
```

- exact final landing on `main:22` triggers zero-cost transition to `loop:0`; passing does nothing.
- exit gate is `loop:4`; exact final landing transfers zero-cost to `main:23`; passing does not exit.
- `loop:0 + 4` exits, while `loop:2 + 4` finishes at `loop:6`.
- stable position may not be `main:22` or `loop:4`.
- `steps_to_exit = posmod(4 - current_index, 8)` and is 1..7 for stable positions.

## Movement

`advance(position, distance, route_choice="")`:

- position has `route_id` and `tile_index`; distance is integer 1..6.
- invalid input is never clamped, wrapped, or defaulted, and never partially moves.
- route choice is accepted only when starting `main:12`; values are `main` and `bypass_sirocco`.
- reaching `main:12` with steps remaining and no choice returns `CHOICE_REQUIRED` with unspent distance.
- exact landing on 12 is ordinary finish; choice occurs on next advance.
- main choice makes the next step `main:13`; bypass choice makes it `bypass:0`.
- leaving bypass:3 consumes one step and lands on main:20.
- reaching main:31 returns `BOSS_GATE_REACHED`, discards and reports surplus steps, never wraps.
- advancing from main:31 returns `AT_BOSS_GATE`.
- next lap transition to main:0 is external after boss resolution.

Every result includes `ok`, `status`, `position`, `steps_consumed`, `remaining_steps`, `path`, `transitions`, `route_choice_used`, `loop_wraps`, `boss_gate_reached`, `error`.

Required errors: `INVALID_POSITION_SHAPE`, `UNKNOWN_ROUTE`, `INDEX_OUT_OF_RANGE`, `INVALID_DISTANCE`, `INVALID_ROUTE_CHOICE`, `UNEXPECTED_ROUTE_CHOICE`, `TRANSIENT_POSITION`, `AT_BOSS_GATE`, `INVALID_COURSE_DATA`.

## Data

Canonical file is `data/stages/v06_cairo_course.json`, schema version 1, course id `cairo_v06`. It contains complete ordered `main`, `bypass`, and `loop` arrays plus fixed entry/rejoin/trigger/return metadata and expected distances.

Validation requires exact route IDs; contiguous unique indices equal to offsets; exact counts and kinds; valid references; five standard preparation spaces; zero bypass preparation and two bypass risks; eight loop spaces with four benefits, two risks, entry and exit; no silent defaults.
