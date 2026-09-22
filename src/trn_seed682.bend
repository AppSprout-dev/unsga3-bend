# RankNicheDistance key-order lock. Not an IGD / A/B run.
# Audit pair, seed 682: same rank, same niche count, same associated
# reference. Closer parent is objectives (0.2, 0.8) at perp dist 0.1;
# farther is (0.3, 0.7) at 0.9. The first LCG draw is about 0.5003787,
# so a coin picks the farther parent. Distance must win before the coin.
# PymooCompatible on the same pair also returns the closer parent.
# A/B default stays PymooCompatible.

import Base
import ./individual.bend as Ind
import ./tournament.bend as Tour
import ./rng.bend as Rng
import ./util.bend as Util

def closer() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([0.2, 0.8]), 0n, 0n, 0n, 0.1)

def farther() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([0.3, 0.7]), 0n, 0n, 0n, 0.9)

def low_niche() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([0.2, 0.8]), 0n, 0n, 0n, 0.9)

def high_niche() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([0.3, 0.7]), 0n, 4n, 0n, 0.1)

def worse_rank() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([0.4, 0.6]), 1n, 0n, 0n, 0.1)

def better_rank() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([0.2, 0.8]), 0n, 9n, 0n, 0.9)

def tie_a() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([0.2, 0.8]), 0n, 0n, 0n, 0.5)

def tie_b() -> Ind.Individual:
  Ind.stamp(Ind.from_objectives([0.3, 0.7]), 0n, 0n, 0n, 0.5)

def seed682() -> Rng.State:
  Rng.from_nat(682n)

def line(ok: Bool, label: String) -> String:
  match ok:
    case True{}:
      "ok " ++ label
    case False{}:
      "FAIL " ++ label

def obj_is(+expect: List<&2, F32>, pair: Rng.State & Ind.Individual) -> Bool:
  (rng, w) = pair
  Util.f32s_eq(expect, Ind.objectives(w))

def dist_is(+expect: F32, pair: Rng.State & Ind.Individual) -> Bool:
  (rng, w) = pair
  F32.is_eq(expect, Ind.perp_dist(w))

def draw_is(+expect: F32, pair: Rng.State & Ind.Individual) -> Bool:
  (rng, w) = pair
  F32.is_eq(expect, Rng.last_double(rng))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(line(obj_is([0.2, 0.8], Tour.winner(Tour.rank_niche(), closer(), farther(), seed682())), "rn682"))
    IO.print(line(dist_is(0.1, Tour.winner(Tour.rank_niche(), closer(), farther(), seed682())), "rn682_dist"))
    IO.print(line(draw_is(0.0, Tour.winner(Tour.rank_niche(), closer(), farther(), seed682())), "rn682_nocoin"))
    IO.print(line(obj_is([0.2, 0.8], Tour.winner(Tour.pymoo(), closer(), farther(), seed682())), "pymoo682"))
    IO.print(line(obj_is([0.2, 0.8], Tour.winner(Tour.rank_niche(), low_niche(), high_niche(), seed682())), "niche_beats_dist"))
    IO.print(line(obj_is([0.2, 0.8], Tour.winner(Tour.rank_niche(), worse_rank(), better_rank(), seed682())), "rank_beats_dist"))
    IO.print(line(obj_is([0.3, 0.7], Tour.winner(Tour.rank_niche(), tie_a(), tie_b(), seed682())), "coin_picks_farther"))
