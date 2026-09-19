# Unsga3Algorithm.Run — C# Unsga3.Algorithm.Unsga3Algorithm.
# init → evaluate → loop: tournament parents → SBX (η=30, p=1.0) →
# polynomial mutation (η=20, p=1/n) → evaluate → survival Select
# with persistent Normalization. Defaults match C# operator defaults.
# Mating tournament for A/B is PymooCompatible (document RankNicheDistance
# as the C# ctor default). Survival niching in Run threads rng (C#
# Select(..., rng): random among equal min-count niches). Empty niches
# take closest; extras are random among near-best on that ray. Uniform
# inNiche[Next] with this LCG collapsed oracle ZDT2.
# Duplicate keys use C# G12-style 12-decimal rounding, not bit-exact F32.

import Base
import ./individual.bend as Ind
import ./non_dominated_sort.bend as NDS
import ./normalization.bend as Norm
import ./reference_directions.bend as Refs
import ./survival.bend as Surv
import ./bounds.bend as Bounds
import ./rng.bend as Rng
import ./sbx.bend as Sbx
import ./polynomial_mutation.bend as Poly
import ./problems.bend as Prob
import ./tournament.bend as Tour
import ./util.bend as Util

type Config is Data:
  MkConfig{
    dirs: List<&2, List<&2, F32>>
    pop_size: Nat
    gens: Nat
    seed: Nat
    mode: Tour.Mode
    elim_dups: Bool
  }

def mk(+dirs: List<&2, List<&2, F32>>, +pop_size: Nat, +gens: Nat, +seed: Nat, +mode: Tour.Mode, +elim_dups: Bool) -> Config:
  MkConfig{dirs, pop_size, gens, seed, mode, elim_dups}

def cfg_dirs(c: Config) -> List<&2, List<&2, F32>>:
  match c:
    case MkConfig{dirs, pop_size, gens, seed, mode, elim_dups}:
      dirs

def cfg_pop(c: Config) -> Nat:
  match c:
    case MkConfig{dirs, pop_size, gens, seed, mode, elim_dups}:
      pop_size

def cfg_gens(c: Config) -> Nat:
  match c:
    case MkConfig{dirs, pop_size, gens, seed, mode, elim_dups}:
      gens

def cfg_seed(c: Config) -> Nat:
  match c:
    case MkConfig{dirs, pop_size, gens, seed, mode, elim_dups}:
      seed

def cfg_mode(c: Config) -> Tour.Mode:
  match c:
    case MkConfig{dirs, pop_size, gens, seed, mode, elim_dups}:
      mode

def cfg_elim(c: Config) -> Bool:
  match c:
    case MkConfig{dirs, pop_size, gens, seed, mode, elim_dups}:
      elim_dups

# Smoke (not oracle): ZDT1 n=30, partitions=4 → 5 refs, pop=8, gens=3, seed=1.
def smoke_zdt1() -> Config:
  mk(Refs.das_dennis(2n, 4n), 8n, 3n, 1n, Tour.pymoo(), True{})

# C# OracleCompare / EQUIVALENCE-style settings (not the smoke default).
def oracle_zdt1() -> Config:
  mk(Refs.das_dennis(2n, 12n), 52n, 100n, 1n, Tour.pymoo(), True{})

def oracle_dtlz2() -> Config:
  mk(Refs.das_dennis(3n, 12n), 92n, 150n, 1n, Tour.pymoo(), True{})

def get_ind(+pop: List<&2, Ind.Individual>, i: Nat) -> Ind.Individual:
  Maybe.default(&2, Ind.Individual, List.get(&2, Ind.Individual, pop, i), Ind.from_variables(Nil{}, 1n))

def rand_xs.go(+box: Bounds.Box, fuel: Nat, +i: Nat, rng: Rng.State, acc: List<&2, F32>) -> Rng.State & List<&2, F32>:
  match fuel:
    case 0n:
      (rng, List.reverse(&2, F32, acc))
    case 1n+f:
      +iv = Bounds.at(box, i)
      +rng2 = Rng.next_double(rng)
      +lo = Bounds.lo(iv)
      +hi = Bounds.hi(iv)
      rand_xs.go(
        box,
        f,
        1n+i,
        rng2,
        F32.add(lo, F32.mul(F32.sub(hi, lo), Rng.last_double(rng2))) <> acc
      )

def rand_xs(+box: Bounds.Box, rng: Rng.State) -> Rng.State & List<&2, F32>:
  rand_xs.go(box, Bounds.n_var(box), 0n, rng, Nil{})

type IHold is Data:
  IH{
    rng: Rng.State
    acc: List<&2, Ind.Individual>
  }

def init_next.xs(+n_obj: Nat, acc: List<&2, Ind.Individual>, pair: Rng.State & List<&2, F32>) -> IHold:
  (rng, xs) = pair
  IH{rng, Ind.from_variables(xs, n_obj) <> acc}

def init_next(+box: Bounds.Box, +n_obj: Nat, hold: IHold) -> IHold:
  match hold:
    case IH{rng, acc}:
      init_next.xs(n_obj, acc, rand_xs(box, rng))

def init_loop(fuel: Nat, hold: IHold, +box: Bounds.Box, +n_obj: Nat) -> Rng.State & List<&2, Ind.Individual>:
  match fuel hold:
    case 0n IH{rng, acc}:
      (rng, List.reverse(&2, Ind.Individual, acc))
    case 1n+f h:
      init_loop(f, init_next(box, n_obj, h), box, n_obj)

def init_pop(+prob: Prob.Problem, n: Nat, rng: Rng.State) -> Rng.State & List<&2, Ind.Individual>:
  init_loop(n, IH{rng, Nil{}}, Prob.box_of(prob), Prob.n_obj(prob))

def vars_of.go(xs: List<&2, Ind.Individual>, acc: List<&2, List<&2, F32>>) -> List<&2, List<&2, F32>>:
  match xs:
    case Nil{}:
      List.reverse(&2, List<&2, F32>, acc)
    case +ind <> rest:
      vars_of.go(rest, Util.g12_vec(Ind.variables(ind)) <> acc)

def vars_of(xs: List<&2, Ind.Individual>) -> List<&2, List<&2, F32>>:
  vars_of.go(xs, Nil{})

def try_add.go(+acc: List<&2, Ind.Individual>, +child: Ind.Individual, +seen: List<&2, List<&2, F32>>, +key: List<&2, F32>, skip: Bool) -> List<&2, Ind.Individual> & List<&2, List<&2, F32>> & Bool:
  match skip:
    case True{}:
      (acc, seen, False{})
    case False{}:
      (List.append(&2, Ind.Individual, acc, [child]), key <> seen, True{})

def try_add(+acc: List<&2, Ind.Individual>, +child: Ind.Individual, +seen: List<&2, List<&2, F32>>, elim: Bool) -> List<&2, Ind.Individual> & List<&2, List<&2, F32>> & Bool:
  +key = Util.g12_vec(Ind.variables(child))
  try_add.go(acc, child, seen, key, Bool.and(elim, Util.has_f32s(key, seen)))

def pred_or_zero(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      p

def dec_if(n: Nat, hit: Bool) -> Nat:
  match hit:
    case True{}:
      pred_or_zero(n)
    case False{}:
      n

def wrap_pair.go(+pair: Nat, ok: Bool) -> Nat:
  match ok:
    case True{}:
      pair
    case False{}:
      0n

def wrap_pair(+pair: Nat, +n: Nat) -> Nat:
  wrap_pair.go(pair, Nat.is_lt(1n+pair, n))

type FHold is Data:
  FH{
    rng: Rng.State
    acc: List<&2, Ind.Individual>
  }

def fallback_next.m(acc: List<&2, Ind.Individual>, pair: Rng.State & Ind.Individual) -> FHold:
  (rng, extra) = pair
  FH{rng, List.append(&2, Ind.Individual, acc, [extra])}

def fallback_next(+parents: List<&2, Ind.Individual>, +prob: Prob.Problem, +mut_p: F32, hold: FHold) -> FHold:
  match hold:
    case FH{rng, acc}:
      +n = Util.list_len(Ind.Individual, parents)
      +rng_i = Rng.next_nat(rng, n)
      fallback_next.m(acc, Poly.mutate(Poly.default(), get_ind(parents, Rng.last_nat(rng_i)), Prob.box_of(prob), rng_i, mut_p))

def fallback_loop(need: Nat, hold: FHold, +parents: List<&2, Ind.Individual>, +prob: Prob.Problem, +mut_p: F32) -> Rng.State & List<&2, Ind.Individual>:
  match need hold:
    case 0n FH{rng, acc}:
      (rng, acc)
    case 1n+k h:
      fallback_loop(k, fallback_next(parents, prob, mut_p, h), parents, prob, mut_p)

def offs_add2.hit(+need1: Nat, trip: List<&2, Ind.Individual> & List<&2, List<&2, F32>> & Bool) -> Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>:
  (acc2, seen2, hit2) = trip
  (dec_if(need1, hit2), acc2, seen2)

def offs_add2.rest(+need1: Nat, +elim: Bool, +c2: Ind.Individual, acc1: List<&2, Ind.Individual>, seen1: List<&2, List<&2, F32>>, done: Bool) -> Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>:
  match done:
    case True{}:
      (0n, acc1, seen1)
    case False{}:
      offs_add2.hit(need1, try_add(acc1, c2, seen1, elim))

def offs_add2(
  +need: Nat,
  acc: List<&2, Ind.Individual>,
  seen: List<&2, List<&2, F32>>,
  +elim: Bool,
  +c2: Ind.Individual,
  trip: List<&2, Ind.Individual> & List<&2, List<&2, F32>> & Bool
) -> Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>:
  (acc1, seen1, hit1) = trip
  +need1 = dec_if(need, hit1)
  offs_add2.rest(need1, elim, c2, acc1, seen1, Nat.is_eq(need1, 0n))

def offs_pair.done(rng3: Rng.State, trip: Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>) -> Rng.State & Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>:
  (need2, acc2, seen2) = trip
  (rng3, need2, acc2, seen2)

def offs_pair.m2(+need: Nat, +acc: List<&2, Ind.Individual>, +seen: List<&2, List<&2, F32>>, +elim: Bool, +m1: Ind.Individual, pair: Rng.State & Ind.Individual) -> Rng.State & Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>:
  (rng3, m2) = pair
  offs_pair.done(rng3, offs_add2(need, acc, seen, elim, m2, try_add(acc, m1, seen, elim)))

def offs_pair.m1(+need: Nat, +acc: List<&2, Ind.Individual>, +seen: List<&2, List<&2, F32>>, +prob: Prob.Problem, +mut_p: F32, +elim: Bool, +c2: Ind.Individual, pair: Rng.State & Ind.Individual) -> Rng.State & Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>:
  (rng2, m1) = pair
  offs_pair.m2(need, acc, seen, elim, m1, Poly.mutate(Poly.default(), c2, Prob.box_of(prob), rng2, mut_p))

def offs_pair.sbx(+need: Nat, +acc: List<&2, Ind.Individual>, +seen: List<&2, List<&2, F32>>, +prob: Prob.Problem, +mut_p: F32, +elim: Bool, trip: Rng.State & Ind.Individual & Ind.Individual) -> Rng.State & Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>:
  (rng1, c1, c2) = trip
  offs_pair.m1(need, acc, seen, prob, mut_p, elim, c2, Poly.mutate(Poly.default(), c1, Prob.box_of(prob), rng1, mut_p))

def offs_pair(
  +parents: List<&2, Ind.Individual>,
  +pair: Nat,
  +need: Nat,
  +acc: List<&2, Ind.Individual>,
  +seen: List<&2, List<&2, F32>>,
  rng: Rng.State,
  +prob: Prob.Problem,
  +mut_p: F32,
  +elim: Bool
) -> Rng.State & Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>:
  +n = Util.list_len(Ind.Individual, parents)
  +p0 = wrap_pair(pair, n)
  offs_pair.sbx(
    need,
    acc,
    seen,
    prob,
    mut_p,
    elim,
    Sbx.crossover(Sbx.default(), get_ind(parents, p0), get_ind(parents, 1n+p0), Prob.box_of(prob), rng)
  )

type OHold is Data:
  OH{
    need: Nat
    pair: Nat
    rng: Rng.State
    acc: List<&2, Ind.Individual>
    seen: List<&2, List<&2, F32>>
  }

def offs_next.q(+pair0: Nat, quad: Rng.State & Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>) -> OHold:
  (rng, need, acc, seen) = quad
  OH{need, Nat.add(pair0, 2n), rng, acc, seen}

def offs_next(+parents: List<&2, Ind.Individual>, +prob: Prob.Problem, +mut_p: F32, +elim: Bool, hold: OHold) -> OHold:
  match hold:
    case OH{need, +pair, rng, acc, seen}:
      offs_next.q(pair, offs_pair(parents, pair, need, acc, seen, rng, prob, mut_p, elim))

def offs_done(+parents: List<&2, Ind.Individual>, +prob: Prob.Problem, +mut_p: F32, hold: OHold) -> Rng.State & List<&2, Ind.Individual>:
  match hold:
    case OH{nrest, pair, rng, acc, seen}:
      fallback_loop(nrest, FH{rng, acc}, parents, prob, mut_p)

def offs_have(hold: OHold) -> Rng.State & List<&2, Ind.Individual>:
  match hold:
    case OH{need, pair, rng, acc, seen}:
      (rng, acc)

def offs_loop(
  fuel: Nat,
  hold: OHold,
  +parents: List<&2, Ind.Individual>,
  +prob: Prob.Problem,
  +mut_p: F32,
  +elim: Bool
) -> Rng.State & List<&2, Ind.Individual>:
  match fuel hold:
    case 0n h:
      offs_done(parents, prob, mut_p, h)
    case 1n+f OH{0n, pair, rng, acc, seen}:
      offs_have(OH{0n, pair, rng, acc, seen})
    case 1n+f OH{1n+k, pair, rng, acc, seen}:
      offs_loop(f, offs_next(parents, prob, mut_p, elim, OH{1n+k, pair, rng, acc, seen}), parents, prob, mut_p, elim)

def seen_start(+parents: List<&2, Ind.Individual>, elim: Bool) -> List<&2, List<&2, F32>>:
  match elim:
    case True{}:
      vars_of(parents)
    case False{}:
      Nil{}

def create_offspring(+prob: Prob.Problem, +parents: List<&2, Ind.Individual>, +n: Nat, rng: Rng.State, +elim: Bool) -> Rng.State & List<&2, Ind.Individual>:
  offs_loop(
    Nat.mul(n, 40n),
    OH{n, 0n, rng, Nil{}, seen_start(parents, elim)},
    parents,
    prob,
    Poly.typical_probability(Prob.n_var(prob)),
    elim
  )

def nd_front(+pop: List<&2, Ind.Individual>) -> List<&2, Ind.Individual>:
  Surv.gather(pop, Surv.front0(NDS.sort(pop)))

def emit_front(xs: List<&2, Ind.Individual>) -> IO(Unit):
  match xs:
    case Nil{}:
      do IO<Unit>:
        return Unit{}
    case ind <> rest:
      do IO<Unit>:
        IO.print(Util.show_f32s(Ind.objectives(ind)))
        emit_front(rest)

type GHold is Data:
  GH{
    st: Norm.State
    xs: List<&2, Ind.Individual>
    rng: Rng.State
  }

def one_gen.prep(+rng: Rng.State, pair: Norm.State & List<&2, Ind.Individual>) -> GHold:
  (st, xs) = pair
  GH{st, xs, rng}

def one_gen.s(+prob: Prob.Problem, +cfg: Config, trip: Norm.State & List<&2, Ind.Individual> & Rng.State) -> GHold:
  (st, xs, rng) = trip
  one_gen.prep(rng, Tour.prepare(xs, cfg_dirs(cfg), st))

def one_gen.o(+prob: Prob.Problem, +cfg: Config, +pop: List<&2, Ind.Individual>, +state: Norm.State, trip: Rng.State & List<&2, Ind.Individual>) -> GHold:
  (rng2, offs) = trip
  one_gen.s(
    prob,
    cfg,
    Surv.select_st(
      List.append(&2, Ind.Individual, pop, Prob.evaluate_all(prob, offs)),
      cfg_pop(cfg),
      cfg_dirs(cfg),
      state,
      rng2
    )
  )

def one_gen.p(+prob: Prob.Problem, +cfg: Config, +pop: List<&2, Ind.Individual>, +state: Norm.State, trip: Rng.State & List<&2, Ind.Individual>) -> GHold:
  (rng1, parents) = trip
  one_gen.o(prob, cfg, pop, state, create_offspring(prob, parents, cfg_pop(cfg), rng1, cfg_elim(cfg)))

def one_gen(+prob: Prob.Problem, +cfg: Config, hold: GHold) -> GHold:
  match hold:
    case GH{st, +xs, rng}:
      one_gen.p(prob, cfg, xs, st, Tour.select_parents(cfg_mode(cfg), xs, cfg_pop(cfg), rng))

def gen_pop(hold: GHold) -> List<&2, Ind.Individual>:
  match hold:
    case GH{st, xs, rng}:
      xs

def gen_loop(fuel: Nat, hold: GHold, +prob: Prob.Problem, +cfg: Config) -> List<&2, Ind.Individual>:
  match fuel hold:
    case 0n h:
      gen_pop(h)
    case 1n+g h:
      gen_loop(g, one_gen(prob, cfg, h), prob, cfg)

def run.after_prep(+prob: Prob.Problem, +cfg: Config, rng: Rng.State, pair: Norm.State & List<&2, Ind.Individual>) -> List<&2, Ind.Individual>:
  (st1, pop1) = pair
  gen_loop(cfg_gens(cfg), GH{st1, pop1, rng}, prob, cfg)

def run.go(+prob: Prob.Problem, +cfg: Config, pair: Rng.State & List<&2, Ind.Individual>) -> List<&2, Ind.Individual>:
  (rng, raw) = pair
  run.after_prep(prob, cfg, rng, Tour.prepare(Prob.evaluate_all(prob, raw), cfg_dirs(cfg), Norm.new_state(Prob.n_obj(prob))))

def run.sized(+prob: Prob.Problem, +cfg: Config, n: Nat) -> List<&2, Ind.Individual>:
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      run.go(prob, cfg, init_pop(prob, 1n+p, Rng.from_nat(cfg_seed(cfg))))

def run(+prob: Prob.Problem, +cfg: Config) -> List<&2, Ind.Individual>:
  +n = cfg_pop(cfg)
  Util.list_take_pad(Ind.Individual, Ind.from_objectives(Nil{}), run.sized(prob, cfg, n), n)

def run_zdt1_smoke() -> List<&2, Ind.Individual>:
  run(Prob.zdt1(30n), smoke_zdt1())
