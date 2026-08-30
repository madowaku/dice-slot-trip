"""Reproducible economy audit for the six Las Vegas casino games.

This mirrors the authored payout tables and uses optimal stopping/holding where
the UI exposes a decision.  It intentionally does not modify game data.
"""

from __future__ import annotations

from collections import Counter
from functools import lru_cache
from itertools import product
from math import factorial
import json
from pathlib import Path
import random

import numpy as np


BET = 20
SEED = 20260830
TRIALS = 100_000


def gd_round(value: float) -> int:
    return int(value + 0.5)


def normalize(dist: dict[int, float]) -> dict[int, float]:
    total = sum(dist.values())
    return {int(k): float(v / total) for k, v in sorted(dist.items()) if v > 0}


def dist_mean(dist: dict[int, float]) -> float:
    return sum(value * probability for value, probability in dist.items())


def mix_dists(dists: list[dict[int, float]]) -> dict[int, float]:
    out: Counter[int] = Counter()
    for dist in dists:
        for value, probability in dist.items():
            out[value] += probability / len(dists)
    return normalize(dict(out))


TOWER_MULTIPLIERS = {1: 1.10, 2: 1.25, 3: 1.50, 4: 1.80, 5: 2.00,
                     6: 2.30, 7: 2.70, 8: 3.10, 9: 3.60, 10: 4.20}


@lru_cache(None)
def tower_opt(bet: int, floor: int) -> tuple[float, str, tuple[tuple[int, float], ...]]:
    if floor >= 10:
        payout = gd_round(bet * TOWER_MULTIPLIERS[10])
        return float(payout), "complete", ((payout, 1.0),)
    cash = gd_round(bet * TOWER_MULTIPLIERS[floor]) if floor else -1
    roll_dist: Counter[int] = Counter({0: 1 / 6})
    roll_value = 0.0
    for face in range(2, 7):
        next_floor = min(10, floor + (2 if face == 6 else 1))
        value, _, next_items = tower_opt(bet, next_floor)
        roll_value += value / 6
        for payout, probability in next_items:
            roll_dist[payout] += probability / 6
    if floor and cash >= roll_value:
        return float(cash), "cashout", ((cash, 1.0),)
    return roll_value, "roll", tuple(normalize(dict(roll_dist)).items())


@lru_cache(None)
def tower_threshold(bet: int, floor: int, cashout_floor: int) -> tuple[tuple[int, int, float], ...]:
    """Return (payout, terminal floor, probability) for a fixed cash-out policy.

    cashout_floor 1..9 takes the first reachable floor at or above the threshold;
    10 means the explicit completion-only policy.
    """
    if floor >= 10:
        return ((gd_round(bet * TOWER_MULTIPLIERS[10]), 10, 1.0),)
    if floor >= cashout_floor and floor > 0:
        return ((gd_round(bet * TOWER_MULTIPLIERS[floor]), floor, 1.0),)
    out: Counter[tuple[int, int]] = Counter({(0, floor): 1 / 6})
    for face in range(2, 7):
        next_floor = min(10, floor + (2 if face == 6 else 1))
        for payout, terminal_floor, probability in tower_threshold(bet, next_floor, cashout_floor):
            out[(payout, terminal_floor)] += probability / 6
    return tuple((payout, terminal_floor, probability)
                 for (payout, terminal_floor), probability in sorted(out.items()))


def tower_policy_report(bet: int, cashout_floor: int) -> dict:
    outcomes = tower_threshold(bet, 0, cashout_floor)
    payout_dist: Counter[int] = Counter()
    floor_dist: Counter[int] = Counter()
    for payout, terminal_floor, probability in outcomes:
        payout_dist[payout] += probability
        if payout > 0:
            floor_dist[terminal_floor] += probability
    normalized = normalize(dict(payout_dist))
    return {
        "rtp": round(dist_mean(normalized) / bet, 8),
        "bust_rate": round(float(payout_dist[0]), 8),
        "cashout_floors": {str(floor): round(probability, 8)
                           for floor, probability in sorted(floor_dist.items()) if floor > 0},
        "payout_distribution": {str(payout): round(probability, 10)
                                for payout, probability in normalized.items()},
    }


@lru_cache(None)
def tower_opt_outcomes(bet: int, floor: int = 0) -> tuple[tuple[int, int, float], ...]:
    _, decision, _ = tower_opt(bet, floor)
    if floor >= 10 or decision == "complete":
        return ((gd_round(bet * TOWER_MULTIPLIERS[10]), 10, 1.0),)
    if decision == "cashout":
        return ((gd_round(bet * TOWER_MULTIPLIERS[floor]), floor, 1.0),)
    out: Counter[tuple[int, int]] = Counter({(0, floor): 1 / 6})
    for face in range(2, 7):
        next_floor = min(10, floor + (2 if face == 6 else 1))
        for payout, terminal_floor, probability in tower_opt_outcomes(bet, next_floor):
            out[(payout, terminal_floor)] += probability / 6
    return tuple((payout, terminal_floor, probability)
                 for (payout, terminal_floor), probability in sorted(out.items()))


def tower_optimal_report(bet: int) -> dict:
    outcomes = tower_opt_outcomes(bet)
    payout_dist: Counter[int] = Counter()
    floor_dist: Counter[int] = Counter()
    for payout, terminal_floor, probability in outcomes:
        payout_dist[payout] += probability
        if payout > 0:
            floor_dist[terminal_floor] += probability
    return {
        "rtp": round(dist_mean(dict(payout_dist)) / bet, 8),
        "bust_rate": round(float(payout_dist[0]), 8),
        "cashout_floors": {str(floor): round(probability, 8)
                           for floor, probability in sorted(floor_dist.items()) if floor > 0},
        "decisions": {str(floor): tower_opt(bet, floor)[1] for floor in range(10)},
        "payout_distribution": {str(payout): round(probability, 10)
                                for payout, probability in normalize(dict(payout_dist)).items()},
    }


TREASURE_NORMAL = {17: 0.4, 18: 0.55, 19: 0.8, 20: 1.0, 21: 1.7}
TREASURE_GOLDEN = {18: 1.25, 19: 1.4, 20: 1.6}


@lru_cache(None)
def treasure_opt(total: int, golden: int) -> tuple[float, str, tuple[tuple[int, float], ...]]:
    cash = int(BET * TREASURE_NORMAL[total]) if total >= 17 else -1
    roll_dist: Counter[int] = Counter()
    roll_value = 0.0
    for face in range(1, 7):
        nxt = total + face
        if nxt > 21:
            payout = 0
            items = ((0, 1.0),)
        elif nxt == 21:
            payout = int(BET * TREASURE_NORMAL[21])
            items = ((payout, 1.0),)
        elif nxt == golden:
            payout = int(BET * TREASURE_GOLDEN[golden])
            items = ((payout, 1.0),)
        else:
            payout, _, items = treasure_opt(nxt, golden)
        roll_value += payout / 6
        for result, probability in items:
            roll_dist[result] += probability / 6
    if total >= 17 and cash >= roll_value:
        return float(cash), "cashout", ((cash, 1.0),)
    return roll_value, "roll", tuple(normalize(dict(roll_dist)).items())


@lru_cache(None)
def treasure_policy(total: int, golden: int, policy: str) -> tuple[tuple[int, float], ...]:
    should_cash = False
    if total >= 17:
        if policy == "general":
            should_cash = total >= 18
        elif policy == "sloppy":
            should_cash = False
    if should_cash:
        return ((int(BET * TREASURE_NORMAL[total]), 1.0),)
    result: Counter[int] = Counter()
    for face in range(1, 7):
        nxt = total + face
        if nxt > 21:
            child = ((0, 1.0),)
        elif nxt == 21:
            child = ((int(BET * TREASURE_NORMAL[21]), 1.0),)
        elif nxt == golden:
            child = ((int(BET * TREASURE_GOLDEN[golden]), 1.0),)
        else:
            child = treasure_policy(nxt, golden, policy)
        for payout, probability in child:
            result[payout] += probability / 6
    return tuple(normalize(dict(result)).items())


POKER_MULTIPLIERS = {
    "none": 0.0, "pair": 0.2, "two_pair": 0.4, "three": 0.6,
    "straight": 0.8, "full_house": 1.0, "four": 1.7, "five": 2.8,
}


def poker_rank(counts: tuple[int, ...]) -> str:
    frequencies = sorted(x for x in counts if x)
    faces = [i + 1 for i, count in enumerate(counts) for _ in range(count)]
    if 5 in frequencies:
        return "five"
    if 4 in frequencies:
        return "four"
    if frequencies == [2, 3]:
        return "full_house"
    if faces in ([1, 2, 3, 4, 5], [2, 3, 4, 5, 6]):
        return "straight"
    if 3 in frequencies:
        return "three"
    if frequencies.count(2) == 2:
        return "two_pair"
    if 2 in frequencies:
        return "pair"
    return "none"


def poker_payout(counts: tuple[int, ...]) -> int:
    return int(BET * POKER_MULTIPLIERS[poker_rank(counts)])


@lru_cache(None)
def roll_count_distributions(n: int) -> tuple[tuple[tuple[int, ...], float], ...]:
    rows = []
    for counts in product(range(n + 1), repeat=6):
        if sum(counts) != n:
            continue
        permutations = factorial(n)
        for count in counts:
            permutations //= factorial(count)
        rows.append((counts, permutations / (6 ** n)))
    return tuple(rows)


def subcounts(counts: tuple[int, ...]):
    yield from product(*(range(value + 1) for value in counts))


@lru_cache(None)
def poker_opt(counts: tuple[int, ...], rerolls: int) -> tuple[float, tuple[int, ...], tuple[tuple[int, float], ...]]:
    stop_payout = poker_payout(counts)
    best_value = float(stop_payout)
    best_keep = counts
    best_dist = ((stop_payout, 1.0),)
    if rerolls <= 0:
        return best_value, best_keep, best_dist
    for keep in subcounts(counts):
        reroll_n = 5 - sum(keep)
        if reroll_n == 0:
            continue
        value = 0.0
        result_dist: Counter[int] = Counter()
        for rolled, probability in roll_count_distributions(reroll_n):
            nxt = tuple(keep[i] + rolled[i] for i in range(6))
            child_value, _, child_dist = poker_opt(nxt, rerolls - 1)
            value += child_value * probability
            for payout, child_probability in child_dist:
                result_dist[payout] += probability * child_probability
        if value > best_value + 1e-12:
            best_value = value
            best_keep = keep
            best_dist = tuple(normalize(dict(result_dist)).items())
    return best_value, best_keep, best_dist


def poker_initial_dist() -> dict[int, float]:
    out: Counter[int] = Counter()
    for counts, probability in roll_count_distributions(5):
        _, _, final_dist = poker_opt(counts, 2)
        for payout, final_probability in final_dist:
            out[payout] += probability * final_probability
    return normalize(dict(out))


def poker_first_roll_dist() -> dict[int, float]:
    """Beginner policy: accept the initial hand without choosing holds/rerolls."""
    out: Counter[int] = Counter()
    for counts, probability in roll_count_distributions(5):
        out[poker_payout(counts)] += probability
    return normalize(dict(out))


def poker_beginner_keep(counts: tuple[int, ...]) -> tuple[int, ...]:
    """Deterministic visible-rule KEEP heuristic for a participating beginner.

    Prefer the largest repeated face group.  Without a pair, keep the longest
    consecutive run.  Equal candidates resolve by kept count, lowest starting
    face, then the canonical die-index order represented by this face-count
    tuple.  The last key is only a stability fallback after equivalent runs.
    """
    repeated = []
    for face_index, count in enumerate(counts):
        if count >= 2:
            keep = tuple(count if index == face_index else 0 for index in range(6))
            repeated.append((-count, face_index, tuple(index for index in range(5)
                                                       if index < count), keep))
    if repeated:
        return min(repeated)[-1]

    present = [index for index, count in enumerate(counts) if count > 0]
    runs = []
    for start in present:
        end = start
        while end + 1 in present:
            end += 1
        length = end - start + 1
        keep = tuple(1 if start <= index <= end else 0 for index in range(6))
        runs.append((-length, start, tuple(index for index in range(5)
                                           if index < length), keep))
    return min(runs)[-1] if runs else (0, 0, 0, 0, 0, 0)


@lru_cache(None)
def poker_beginner(counts: tuple[int, ...], rerolls: int) -> tuple[tuple[int, float], ...]:
    # Five of a kind is the only obvious completed top hand; otherwise the
    # visible flow consumes both available REROLL opportunities.
    if rerolls <= 0 or max(counts) == 5:
        return ((poker_payout(counts), 1.0),)
    keep = poker_beginner_keep(counts)
    reroll_n = 5 - sum(keep)
    out: Counter[int] = Counter()
    for rolled, probability in roll_count_distributions(reroll_n):
        nxt = tuple(keep[index] + rolled[index] for index in range(6))
        for payout, child_probability in poker_beginner(nxt, rerolls - 1):
            out[payout] += probability * child_probability
    return tuple(normalize(dict(out)).items())


def poker_beginner_dist() -> dict[int, float]:
    out: Counter[int] = Counter()
    for counts, probability in roll_count_distributions(5):
        for payout, final_probability in poker_beginner(counts, 2):
            out[payout] += probability * final_probability
    return normalize(dict(out))


def roulette_high_dist() -> dict[int, float]:
    boosts = [1.0, 1.0, 1.2, 1.5, 2.0, 3.0]
    out: Counter[int] = Counter()
    for red_slot in range(24):
        for blue_slot in range(24):
            for red_face in range(6):
                for blue_face in range(6):
                    payout = 0
                    if 9 <= red_slot <= 13:
                        payout += gd_round(BET * 1.4 * boosts[red_face])
                    if 9 <= blue_slot <= 13:
                        payout += gd_round(BET * 1.4 * boosts[blue_face])
                    out[payout] += 1
    return normalize(dict(out))


def orientations() -> list[dict[str, int]]:
    base = {"top": 1, "bottom": 6, "front": 2, "back": 5, "left": 3, "right": 4}
    queue = [base]
    seen = set()
    out = []
    while queue:
        o = queue.pop(0)
        key = tuple(o[x] for x in ("top", "bottom", "front", "back", "left", "right"))
        if key in seen:
            continue
        seen.add(key)
        out.append(o)
        queue.extend([
            {"top": o["front"], "bottom": o["back"], "front": o["bottom"], "back": o["top"], "left": o["left"], "right": o["right"]},
            {"top": o["top"], "bottom": o["bottom"], "front": o["left"], "back": o["right"], "left": o["back"], "right": o["front"]},
            {"top": o["left"], "bottom": o["right"], "front": o["front"], "back": o["back"], "left": o["bottom"], "right": o["top"]},
        ])
    return out


RACERS = ("camel", "rabbit", "fox", "duck", "dinosaur", "robot")
RACER_DIRECTION = {"fox": "top", "rabbit": "bottom", "duck": "front", "dinosaur": "back", "camel": "left", "robot": "right"}


RACE_RANK_MULTIPLIERS = {1: 1.8, 2: 1.0, 3: 0.8, 4: 0.6, 5: 0.4, 6: 0.3}


def race_once_rank(rng: random.Random, accuracy: float, coast_max: int = 9,
                   skill_roll_limit: int | None = None) -> int:
    all_o = orientations()
    hits = [o for o in all_o if o["bottom"] == 6]
    misses = [o for o in all_o if o["bottom"] != 6]
    racers = {r: {"position": 0, "foxfire": False, "log": False} for r in RACERS}
    candidates: list[str] = []
    roll_count = 0
    winner = ""
    while True:
        skill_active = skill_roll_limit is None or roll_count < skill_roll_limit
        o = rng.choice(hits if skill_active and rng.random() < accuracy else misses if skill_active else all_o)
        if coast_max > 0:
            start_index = all_o.index(o)
            o = all_o[(start_index + rng.randint(0, coast_max)) % len(all_o)]
        roll_count += 1
        assignments = {r: o[RACER_DIRECTION[r]] for r in RACERS}
        if candidates:
            winner = max(candidates, key=lambda r: assignments[r])
            break
        for racer in RACERS:
            state = racers[racer]
            rolled = assignments[racer]
            effective = rolled
            if state["log"]:
                effective = 0 if rolled <= 3 else rolled
                state["log"] = False
            elif state["foxfire"]:
                effective = max(1, rolled - 2)
                state["foxfire"] = False
            landing = state["position"] + effective
            final = landing
            if effective > 0 and landing < 24:
                if landing in (5, 20):
                    state["foxfire"] = True
                elif landing == 10:
                    final += 3
                elif landing == 15:
                    state["log"] = True
            state["position"] = final
        goalers = [r for r in RACERS if racers[r]["position"] >= 24]
        if goalers:
            best = max(racers[r]["position"] for r in goalers)
            candidates = [r for r in goalers if racers[r]["position"] == best]
            if len(candidates) == 1:
                winner = candidates[0]
                break
    ordered = sorted(RACERS, key=lambda r: (
        racers[r]["position"],
        1 if r == winner else 0,
        -RACERS.index(r),
    ), reverse=True)
    return ordered.index("rabbit") + 1


def race_profile(coast_max: int, rank_multipliers: dict[int, float],
                 skill_roll_limit: int | None = None, trials: int = 100_000) -> dict[str, dict]:
    rng = random.Random(SEED)
    rates: dict[str, dict] = {}
    for accuracy in (1 / 6, 0.25, 0.40, 0.60, 0.80, 1.0):
        ranks = Counter(race_once_rank(rng, accuracy, coast_max, skill_roll_limit) for _ in range(trials))
        distribution = {rank: ranks[rank] / trials for rank in range(1, 7)}
        rtp = sum(distribution[rank] * rank_multipliers.get(rank, 0.0) for rank in range(1, 7))
        rates[f"{accuracy:.4f}"] = {
            "win_rate": distribution[1],
            "rank_distribution": {str(rank): distribution[rank] for rank in range(1, 7)},
            "rtp": rtp,
        }
    return rates


def vault_data(repo_root: Path) -> dict:
    return json.loads((repo_root / "data/casino/vault_break_templates.json").read_text(encoding="utf-8"))


def vault_mastered_report(repo_root: Path, bet: int = BET) -> dict[str, dict]:
    data = vault_data(repo_root)
    report = {}
    for tier, config in data["tiers"].items():
        templates = [t for t in data["templates"] if t["tier"] == tier]
        weights = [float(t.get("weight", 1.0)) for t in templates]
        weight_total = sum(weights)
        rates = [float(t["balance"]["optimal_success_rate"]) for t in templates]
        weighted_success = sum(rate * weight for rate, weight in zip(rates, weights)) / weight_total
        payout = int(bet * float(config["payout_multiplier"]))
        template_rtps = [rate * payout / bet for rate in rates]
        report[tier] = {
            "template_count": len(templates),
            "weighted_success_rate": round(weighted_success, 8),
            "payout": payout,
            "weighted_rtp": round(weighted_success * payout / bet, 8),
            "minimum_template_rtp": round(min(template_rtps), 8),
            "maximum_template_rtp": round(max(template_rtps), 8),
        }
    return report


def vault_mastered_dist(repo_root: Path, tier: str = "bronze", bet: int = BET) -> dict[int, float]:
    row = vault_mastered_report(repo_root, bet)[tier]
    success = float(row["weighted_success_rate"])
    return normalize({0: 1 - success, int(row["payout"]): success})


def vault_accepts(lock: dict, face: int) -> bool:
    accepted = {
        "low": (1, 2, 3), "high": (4, 5, 6), "odd": (1, 3, 5),
        "even": (2, 4, 6), "edge": (1, 6),
    }
    rule = lock["rule"]
    return face == int(lock["value"]) if rule == "exact" else face in accepted[rule]


@lru_cache(None)
def vault_random_success(lock_keys: tuple[tuple[str, int], ...], max_rolls: int,
                         rolls_used: int = 0, filled_mask: int = 0) -> float:
    """Exact beginner policy: pick uniformly among every currently valid empty lock."""
    if filled_mask == (1 << len(lock_keys)) - 1:
        return 1.0
    if rolls_used >= max_rolls:
        return 0.0
    chance = 0.0
    for face in range(1, 7):
        valid = []
        for index, (rule, value) in enumerate(lock_keys):
            if filled_mask & (1 << index):
                continue
            lock = {"rule": rule, "value": value}
            if vault_accepts(lock, face):
                valid.append(index)
        if not valid:
            chance += vault_random_success(lock_keys, max_rolls, rolls_used + 1, filled_mask) / 6
        else:
            chance += sum(vault_random_success(lock_keys, max_rolls, rolls_used + 1,
                                               filled_mask | (1 << index))
                          for index in valid) / (6 * len(valid))
    return chance


def vault_random_bronze_dist(repo_root: Path, bet: int = BET) -> dict[int, float]:
    data = vault_data(repo_root)
    templates = [t for t in data["templates"] if t["tier"] == "bronze"]
    successes = []
    for template in templates:
        lock_keys = tuple((lock["rule"], int(lock.get("value", 0))) for lock in template["locks"])
        successes.append(vault_random_success(lock_keys, int(template["max_rolls"])))
    success = sum(successes) / len(successes)
    payout = int(bet * float(data["tiers"]["bronze"]["payout_multiplier"]))
    return normalize({0: 1 - success, payout: success})


def bankroll(dist: dict[int, float], rounds: int, rng: np.random.Generator) -> dict[str, float]:
    values = np.array(list(dist), dtype=np.int64)
    probabilities = np.array([dist[int(v)] for v in values], dtype=float)
    balances = np.full(TRIALS, 300, dtype=np.int64)
    for _ in range(rounds):
        active = balances >= BET
        count = int(active.sum())
        balances[active] += rng.choice(values, size=count, p=probabilities) - BET
    return summarize_balances(balances)


def mixed_bankroll(dists: list[dict[int, float]], rounds: int, rng: np.random.Generator) -> dict[str, float]:
    balances = np.full(TRIALS, 300, dtype=np.int64)
    for index in range(rounds):
        dist = dists[index % len(dists)]
        values = np.array(list(dist), dtype=np.int64)
        probabilities = np.array([dist[int(v)] for v in values], dtype=float)
        active = balances >= BET
        balances[active] += rng.choice(values, size=int(active.sum()), p=probabilities) - BET
    return summarize_balances(balances)


def random_facility_bankroll(dists: list[dict[int, float]], rounds: int,
                             rng: np.random.Generator) -> dict[str, float]:
    """Choose one of the six facilities independently for every active player/round."""
    balances = np.full(TRIALS, 300, dtype=np.int64)
    for _ in range(rounds):
        active_indices = np.flatnonzero(balances >= BET)
        facility_choices = rng.integers(0, len(dists), size=active_indices.size)
        for facility_index, dist in enumerate(dists):
            selected = active_indices[facility_choices == facility_index]
            if not selected.size:
                continue
            values = np.array(list(dist), dtype=np.int64)
            probabilities = np.array([dist[int(v)] for v in values], dtype=float)
            balances[selected] += rng.choice(values, size=selected.size, p=probabilities) - BET
    return summarize_balances(balances)


def summarize_balances(balances: np.ndarray) -> dict[str, float]:
    return {
        "mean": round(float(balances.mean()), 2),
        "median": float(np.median(balances)),
        "p10": float(np.percentile(balances, 10)),
        "p90": float(np.percentile(balances, 90)),
        "bankrupt_pct": round(float((balances < BET).mean() * 100), 2),
        "at_or_above_300_pct": round(float((balances >= 300).mean() * 100), 2),
        "under_100_pct": round(float((balances < 100).mean() * 100), 2),
    }


def main() -> None:
    global BET
    repo_root = Path(__file__).resolve().parents[1]
    race = race_profile(9, RACE_RANK_MULTIPLIERS)
    race_before = race_profile(0, {1: 4.0}, trials=50_000)
    race_random_ranks = race[f"{1 / 6:.4f}"]["rank_distribution"]
    race_skill_ranks = race["0.6000"]["rank_distribution"]
    race_dist = normalize({gd_round(BET * RACE_RANK_MULTIPLIERS[rank]): float(race_random_ranks[str(rank)]) for rank in range(1, 7)})
    race_skill_dist = normalize({gd_round(BET * RACE_RANK_MULTIPLIERS[rank]): float(race_skill_ranks[str(rank)]) for rank in range(1, 7)})
    treasure_sloppy = mix_dists([dict(treasure_policy(0, g, "sloppy")) for g in (18, 19, 20)])
    treasure_general = mix_dists([dict(treasure_policy(0, g, "general")) for g in (18, 19, 20)])
    treasure_optimal = mix_dists([dict(treasure_opt(0, g)[2]) for g in (18, 19, 20)])
    tower_optimal_dist = dict(tower_opt(BET, 0)[2])
    tower_beginner_counter: Counter[int] = Counter()
    for payout, _, probability in tower_threshold(BET, 0, 1):
        tower_beginner_counter[payout] += probability
    beginner_dists = {
        "dice_race": race_dist,
        "dice_tower": normalize(dict(tower_beginner_counter)),
        "dice_roulette": roulette_high_dist(),
        "treasure_21": treasure_sloppy,
        "dice_poker": poker_beginner_dist(),
        "vault_break": vault_random_bronze_dist(repo_root),
    }
    analysis_dists = {
        "dice_race_random": race_dist,
        "dice_race_60pct_timing": race_skill_dist,
        "dice_tower_beginner_cashout_1f": beginner_dists["dice_tower"],
        "dice_tower_optimal": tower_optimal_dist,
        "dice_roulette_high": beginner_dists["dice_roulette"],
        "treasure_21_sloppy": treasure_sloppy,
        "treasure_21_general": treasure_general,
        "treasure_21_optimal": treasure_optimal,
        "dice_poker_beginner_heuristic": beginner_dists["dice_poker"],
        "dice_poker_first_roll_lower_bound": poker_first_roll_dist(),
        "dice_poker_optimal": poker_initial_dist(),
        "vault_break_bronze_random_valid": beginner_dists["vault_break"],
        "vault_break_bronze_mastered": vault_mastered_dist(repo_root),
    }
    rng = np.random.default_rng(SEED)
    result = {
        "phase": "Las Vegas Phase B",
        "assumptions": {
            "initial_chips": 300, "fixed_bet": BET, "trials": TRIALS, "seed": SEED,
            "rounds": [10, 30, 50, 100],
            "beginner_policies": {
                "dice_race": "random-equivalent STOP timing with the visible coast model",
                "dice_tower": "CASH OUT at the first reachable floor",
                "dice_roulette": "HIGH bet; wheel outcomes remain random",
                "treasure_21": "always HIT until an automatic terminal result",
                "dice_poker": "keep the largest repeated group; otherwise keep the longest consecutive run; consume both rerolls unless five of a kind is complete",
                "vault_break": "BRONZE; choose uniformly among valid empty locks, never discard a placeable die",
            },
        },
        "race_timing": race,
        "race_before_timing": race_before,
        "race_design_alternatives": {
            "payout_only_x0_95": race_profile(0, {1: 0.95}, trials=50_000),
            "one_skilled_roll_x5": race_profile(0, {1: 5.0}, skill_roll_limit=1, trials=50_000),
            "selected_visible_coast_rank_payout": race,
        },
        "optimal_decisions": {
            "tower": {str(f): tower_opt(BET, f)[1] for f in range(10)},
            "treasure": {str(g): {str(t): treasure_opt(t, g)[1] for t in range(17, 22) if t != g and t != 21} for g in (18, 19, 20)},
        },
        "tower_bet_strategy": {},
        "vault_mastered_tiers": vault_mastered_report(repo_root),
        "lower_bounds": {
            "dice_poker_first_roll_only": {
                "policy": "accept the first roll without KEEP or REROLL; excluded from beginner aggregates",
                "rtp": round(dist_mean(poker_first_roll_dist()) / BET, 6),
            },
        },
        "games": {},
    }
    for bet in (10, 20, 50):
        optimal = tower_optimal_report(bet)
        result["tower_bet_strategy"][str(bet)] = {
            "optimal": optimal,
            "policy_thresholds": {
                **{str(floor): tower_policy_report(bet, floor) for floor in range(1, 10)},
                "completion": tower_policy_report(bet, 10),
            },
        }
    for name, dist in analysis_dists.items():
        result["games"][name] = {
            "payout_distribution": {str(k): round(v, 10) for k, v in dist.items()},
            "expected_payout": round(dist_mean(dist), 6),
            "rtp": round(dist_mean(dist) / BET, 6),
            "house_edge": round(1 - dist_mean(dist) / BET, 6),
            "bankroll": {str(n): bankroll(dist, n, rng) for n in (10, 30, 50, 100)},
        }
    result["beginner_bankroll"] = {
        "facilities": {
            name: {str(n): bankroll(dist, n, rng) for n in (10, 30, 50, 100)}
            for name, dist in beginner_dists.items()
        },
        "uniform_rotation": {
            str(n): mixed_bankroll(list(beginner_dists.values()), n, rng)
            for n in (10, 30, 50, 100)
        },
        "independent_random_facility": {
            str(n): random_facility_bankroll(list(beginner_dists.values()), n, rng)
            for n in (10, 30, 50, 100)
        },
    }
    result["bet_sensitivity"] = {}
    for bet in (5, 10, 20, 50):
        BET = bet
        tower_opt.cache_clear()
        treasure_opt.cache_clear()
        treasure_policy.cache_clear()
        poker_opt.cache_clear()
        poker_beginner.cache_clear()
        row = {
            "dice_race_random": race[f"{1 / 6:.4f}"]["rtp"],
            "treasure_21": {
                str(g): dist_mean(dict(treasure_opt(0, g)[2])) / bet for g in (18, 19, 20)
            },
        }
        if bet in (10, 20, 50):
            row.update({
                "dice_tower": dist_mean(dict(tower_opt(bet, 0)[2])) / bet,
                "dice_roulette_high": dist_mean(roulette_high_dist()) / bet,
                "dice_poker": dist_mean(poker_initial_dist()) / bet,
                "vault_break_bronze": dist_mean(vault_mastered_dist(repo_root, bet=bet)) / bet,
            })
        result["bet_sensitivity"][str(bet)] = row
    BET = 20
    tower_opt.cache_clear()
    treasure_opt.cache_clear()
    treasure_policy.cache_clear()
    poker_opt.cache_clear()
    poker_beginner.cache_clear()
    output = repo_root / "artifacts/audit/las-vegas-phase-b-casino-economy-2026-08-30.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(output)
    print(json.dumps({
        "tower_optimal_rtp": {bet: result["tower_bet_strategy"][bet]["optimal"]["rtp"]
                              for bet in ("10", "20", "50")},
        "beginner_rtp": {name: round(dist_mean(dist) / BET, 6)
                         for name, dist in beginner_dists.items()},
        "vault_mastered_rtp": {tier: row["weighted_rtp"]
                               for tier, row in result["vault_mastered_tiers"].items()},
    }, indent=2))


if __name__ == "__main__":
    main()
