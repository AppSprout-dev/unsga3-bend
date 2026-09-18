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

type IPack is Data:
  IPack{
    fuel: Nat
    rng: Rng.State
    xs: List<&2, F32>
  }

def pack_xs(fuel: Nat, pair: Rng.State & List<&2, F32>) -> IPack:
  (rng, xs) = pair
  IPack{fuel, rng, xs}

@unsafe def init_go(+box: Bounds.Box, +n_obj: Nat, acc: List<&2, Ind.Individual>, pack: IPack) -> Rng.State & List<&2, Ind.Individual>:
  match pack:
    case IPack{0n, rng, xs}:
      (rng, List.reverse(&2, Ind.Individual, Ind.from_variables(xs, n_obj) <> acc))
    case IPack{1n+f, rng, xs}:
      init_go(box, n_obj, Ind.from_variables(xs, n_obj) <> acc, pack_xs(f, rand_xs(box, rng)))

def init_loop(+box: Bounds.Box, +n_obj: Nat, fuel: Nat, rng: Rng.State, acc: List<&2, Ind.Individual>) -> Rng.State & List<&2, Ind.Individual>:
  match fuel:
    case 0n:
      (rng, List.reverse(&2, Ind.Individual, acc))
    case 1n+f:
      init_go(box, n_obj, acc, pack_xs(f, rand_xs(box, rng)))

def init_pop(+prob: Prob.Problem, n: Nat, rng: Rng.State) -> Rng.State & List<&2, Ind.Individual>:
  init_loop(Prob.box_of(prob), Prob.n_obj(prob), n, rng, Nil{})

def vars_of(xs: List<&2, Ind.Individual>) -> List<&2, List<&2, F32>>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      Util.g12_vec(Ind.variables(h)) <> vars_of(t)

def try_add.go(+acc: List<&2, Ind.Individual>, +child: Ind.Individual, +seen: List<&2, List<&2, F32>>, skip: Bool) -> List<&2, Ind.Individual> & List<&2, List<&2, F32>> & Bool:
  match skip:
    case True{}:
      (acc, seen, False{})
    case False{}:
      (List.append(&2, Ind.Individual, acc, [child]), Util.g12_vec(Ind.variables(child)) <> seen, True{})

def try_add(+acc: List<&2, Ind.Individual>, +child: Ind.Individual, +seen: List<&2, List<&2, F32>>, elim: Bool) -> List<&2, Ind.Individual> & List<&2, List<&2, F32>> & Bool:
  try_add.go(acc, child, seen, Bool.and(elim, Util.has_f32s(Util.g12_vec(Ind.variables(child)), seen)))

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

type FPack is Data:
  FPack{
    need: Nat
    rng: Rng.State
    extra: Ind.Individual
  }

def pack_fb(need: Nat, pair: Rng.State & Ind.Individual) -> FPack:
  (rng, extra) = pair
  FPack{need, rng, extra}

@unsafe def fallback_go(+parents: List<&2, Ind.Individual>, acc: List<&2, Ind.Individual>, +prob: Prob.Problem, +mut_p: F32, pack: FPack) -> Rng.State & List<&2, Ind.Individual>:
  match pack:
    case FPack{0n, rng, extra}:
      (rng, List.append(&2, Ind.Individual, acc, [extra]))
    case FPack{1n+k, rng, extra}:
      +acc2 = List.append(&2, Ind.Individual, acc, [extra])
      +n = Util.list_len(Ind.Individual, parents)
      +rng_i = Rng.next_nat(rng, n)
      fallback_go(
        parents,
        acc2,
        prob,
        mut_p,
        pack_fb(k, Poly.mutate(Poly.default(), get_ind(parents, Rng.last_nat(rng_i)), Prob.box_of(prob), rng_i, mut_p))
      )

def fallback_loop(+parents: List<&2, Ind.Individual>, need: Nat, acc: List<&2, Ind.Individual>, rng: Rng.State, +prob: Prob.Problem, +mut_p: F32) -> Rng.State & List<&2, Ind.Individual>:
  match need:
    case 0n:
      (rng, acc)
    case 1n+k:
      +n = Util.list_len(Ind.Individual, parents)
      +rng_i = Rng.next_nat(rng, n)
      fallback_go(
        parents,
        acc,
        prob,
        mut_p,
        pack_fb(k, Poly.mutate(Poly.default(), get_ind(parents, Rng.last_nat(rng_i)), Prob.box_of(prob), rng_i, mut_p))
      )

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

type OPack is Data:
  OPack{
    fuel: Nat
    need: Nat
    pair: Nat
    rng: Rng.State
    acc: List<&2, Ind.Individual>
    seen: List<&2, List<&2, F32>>
  }

def pack_offs(fuel: Nat, pair: Nat, quad: Rng.State & Nat & List<&2, Ind.Individual> & List<&2, List<&2, F32>>) -> OPack:
  (rng, need, acc, seen) = quad
  OPack{fuel, need, pair, rng, acc, seen}

@unsafe def offs_go(+parents: List<&2, Ind.Individual>, +prob: Prob.Problem, +mut_p: F32, +elim: Bool, pack: OPack) -> Rng.State & List<&2, Ind.Individual>:
  match pack:
    case OPack{0n, nrest, pair, rng, acc, seen}:
      fallback_loop(parents, nrest, acc, rng, prob, mut_p)
    case OPack{f, 0n, pair, rng, acc, seen}:
      (rng, acc)
    case OPack{1n+f, 1n+k, +pair, rng, acc, seen}:
      offs_go(parents, prob, mut_p, elim, pack_offs(f, Nat.add(pair, 2n), offs_pair(parents, pair, 1n+k, acc, seen, rng, prob, mut_p, elim)))

def offs_loop(
  fuel: Nat,
  +parents: List<&2, Ind.Individual>,
  +pair: Nat,
  need: Nat,
  acc: List<&2, Ind.Individual>,
  seen: List<&2, List<&2, F32>>,
  rng: Rng.State,
  +prob: Prob.Problem,
  +mut_p: F32,
  +elim: Bool
) -> Rng.State & List<&2, Ind.Individual>:
  match fuel need:
    case 0n nrest:
      fallback_loop(parents, nrest, acc, rng, prob, mut_p)
    case f 0n:
      (rng, acc)
    case 1n+f 1n+k:
      offs_go(parents, prob, mut_p, elim, pack_offs(f, Nat.add(pair, 2n), offs_pair(parents, pair, 1n+k, acc, seen, rng, prob, mut_p, elim)))

def seen_start(+parents: List<&2, Ind.Individual>, elim: Bool) -> List<&2, List<&2, F32>>:
  match elim:
    case True{}:
      vars_of(parents)
    case False{}:
      Nil{}

def create_offspring(+prob: Prob.Problem, +parents: List<&2, Ind.Individual>, +n: Nat, rng: Rng.State, +elim: Bool) -> Rng.State & List<&2, Ind.Individual>:
  offs_loop(
    Nat.mul(n, 40n),
    parents,
    0n,
    n,
    Nil{},
    seen_start(parents, elim),
    rng,
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
  HZ{}
  HP{
    rng: Rng.State
    xs: List<&2, Ind.Individual>
  }
  HO{
    rng: Rng.State
    xs: List<&2, Ind.Individual>
  }
  HS{
    st: Norm.State
    xs: List<&2, Ind.Individual>
    rng: Rng.State
  }

def hold_p(pair: Rng.State & List<&2, Ind.Individual>) -> GHold:
  (rng, xs) = pair
  HP{rng, xs}

def hold_o(pair: Rng.State & List<&2, Ind.Individual>) -> GHold:
  (rng, xs) = pair
  HO{rng, xs}

def hold_s(pair: Norm.State & List<&2, Ind.Individual>, rng: Rng.State) -> GHold:
  (st, xs) = pair
  HS{st, xs, rng}

def hold_sr(trip: Norm.State & List<&2, Ind.Individual> & Rng.State) -> GHold:
  (st, xs, rng) = trip
  HS{st, xs, rng}

# tag 0: start a generation (shrink fuel) or return.
# tags 1–4: parents → offspring → select → prepare → back to tag 0.
# @unsafe: tag advances without shrinking fuel.
@unsafe def gen_work(
  tag: Nat,
  hold: GHold,
  fuel: Nat,
  +pop: List<&2, Ind.Individual>,
  +state: Norm.State,
  +rng: Rng.State,
  +prob: Prob.Problem,
  +cfg: Config
) -> List<&2, Ind.Individual>:
  match tag hold:
    case 0n h:
      match fuel:
        case 0n:
          pop
        case 1n+g:
          gen_work(
            1n,
            hold_p(Tour.select_parents(cfg_mode(cfg), pop, cfg_pop(cfg), rng)),
            g,
            pop,
            state,
            rng,
            prob,
            cfg
          )
    case 1n HP{+rng1, parents}:
      gen_work(1n+1n, hold_o(create_offspring(prob, parents, cfg_pop(cfg), rng1, cfg_elim(cfg))), fuel, pop, state, rng1, prob, cfg)
    case 1n+1n HO{+rng2, offs}:
      gen_work(
        1n+1n+1n,
        hold_sr(
          Surv.select_st(
            List.append(&2, Ind.Individual, pop, Prob.evaluate_all(prob, offs)),
            cfg_pop(cfg),
            cfg_dirs(cfg),
            state,
            rng2
          )
        ),
        fuel,
        pop,
        state,
        rng2,
        prob,
        cfg
      )
    case 1n+1n+1n HS{+st2, +next0, +rng2}:
      gen_work(1n+1n+1n+1n, hold_s(Tour.prepare(next0, cfg_dirs(cfg), st2), rng2), fuel, next0, st2, rng2, prob, cfg)
    case 1n+1n+1n+1n+p HS{st3, next1, rng2}:
      gen_work(0n, HZ{}, fuel, next1, st3, rng2, prob, cfg)
    case t h2:
      pop

def run.after_prep(+prob: Prob.Problem, +cfg: Config, rng: Rng.State, pair: Norm.State & List<&2, Ind.Individual>) -> List<&2, Ind.Individual>:
  (st1, pop1) = pair
  gen_work(0n, HZ{}, cfg_gens(cfg), pop1, st1, rng, prob, cfg)

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
  run.sized(prob, cfg, cfg_pop(cfg))

def run_zdt1_smoke() -> List<&2, Ind.Individual>:
  run(Prob.zdt1(30n), smoke_zdt1())
