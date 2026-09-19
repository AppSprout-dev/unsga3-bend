# Wall-clock phase profile of Unsga3Algorithm.Run.
# Same call order as src/algorithm.bend (same RNG / same front).
# Buckets are IO.now() milliseconds (native: io_tick()/1e6).
# Bend 2.0.13 has no sampling profiler (README limitations).
# Mid-split maps stay in the callees; this file only wraps them.

import Base
import ../src/algorithm.bend as Algo
import ../src/individual.bend as Ind
import ../src/non_dominated_sort.bend as NDS
import ../src/normalization.bend as Norm
import ../src/problems.bend as Prob
import ../src/rng.bend as Rng
import ../src/survival.bend as Surv
import ../src/tournament.bend as Tour
import ../src/util.bend as Util

type Buckets is Data:
  Bk{
    init_pop: Nat
    evaluate: Nat
    nds_select: Nat
    nds_prepare: Nat
    nds_final: Nat
    normalize_select: Nat
    normalize_prepare: Nat
    associate_select: Nat
    associate_prepare: Nat
    niche: Nat
    tournament: Nat
    offspring: Nat
  }

def zero() -> Buckets:
  Bk{0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n, 0n}

def add_init(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{Nat.add(a, dt), e, ns, np, nf, zs, zp, asg, ap, ni, t, o}

def add_eval(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, Nat.add(e, dt), ns, np, nf, zs, zp, asg, ap, ni, t, o}

def add_nds_sel(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, Nat.add(ns, dt), np, nf, zs, zp, asg, ap, ni, t, o}

def add_nds_prep(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, Nat.add(np, dt), nf, zs, zp, asg, ap, ni, t, o}

def add_nds_fin(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, np, Nat.add(nf, dt), zs, zp, asg, ap, ni, t, o}

def add_norm_sel(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, np, nf, Nat.add(zs, dt), zp, asg, ap, ni, t, o}

def add_norm_prep(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, np, nf, zs, Nat.add(zp, dt), asg, ap, ni, t, o}

def add_asg_sel(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, np, nf, zs, zp, Nat.add(asg, dt), ap, ni, t, o}

def add_asg_prep(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, np, nf, zs, zp, asg, Nat.add(ap, dt), ni, t, o}

def add_niche(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, np, nf, zs, zp, asg, ap, Nat.add(ni, dt), t, o}

def add_tour(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, Nat.add(t, dt), o}

def add_offs(b: Buckets, dt: Nat) -> Buckets:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, Nat.add(o, dt)}

def elapsed(t0: Nat, t1: Nat) -> Nat:
  Nat.sub(t1, t0)

def pct(+part: Nat, total: Nat) -> Nat:
  match total:
    case 0n:
      0n
    case 1n+p:
      Nat.div(Nat.mul(part, 100n), 1n+p)

def nds_all(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Nat.add(ns, Nat.add(np, nf))

def norm_all(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Nat.add(zs, zp)

def asg_all(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Nat.add(asg, ap)

def bk_init(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      a

def bk_eval(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      e

def bk_nds_sel(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      ns

def bk_nds_prep(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      np

def bk_nds_fin(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      nf

def bk_norm_sel(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      zs

def bk_norm_prep(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      zp

def bk_asg_sel(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      asg

def bk_asg_prep(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      ap

def bk_niche(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      ni

def bk_tour(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      t

def bk_offs(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      o

def bucket_sum(b: Buckets) -> Nat:
  match b:
    case Bk{a, e, ns, np, nf, zs, zp, asg, ap, ni, t, o}:
      Nat.add(a, Nat.add(e, Nat.add(ns, Nat.add(np, Nat.add(nf, Nat.add(zs, Nat.add(zp, Nat.add(asg, Nat.add(ap, Nat.add(ni, Nat.add(t, o)))))))))))

type Hold is Data:
  H{
    st: Norm.State
    xs: List<&2, Ind.Individual>
    rng: Rng.State
  }

type Sel is Data:
  Sel{
    st: Norm.State
    xs: List<&2, Ind.Individual>
    rng: Rng.State
    acc: Buckets
  }

type Prep is Data:
  Prep{
    st: Norm.State
    xs: List<&2, Ind.Individual>
    acc: Buckets
  }

type Step is Data:
  Step{
    hold: Hold
    acc: Buckets
  }

type Front is Data:
  Front{
    xs: List<&2, Ind.Individual>
    acc: Buckets
  }

def cfg_dirs(c: Algo.Config) -> List<&2, List<&2, F32>>:
  Algo.cfg_dirs(c)

def cfg_pop(c: Algo.Config) -> Nat:
  Algo.cfg_pop(c)

def cfg_gens(c: Algo.Config) -> Nat:
  Algo.cfg_gens(c)

def cfg_seed(c: Algo.Config) -> Nat:
  Algo.cfg_seed(c)

def cfg_mode(c: Algo.Config) -> Tour.Mode:
  Algo.cfg_mode(c)

def cfg_elim(c: Algo.Config) -> Bool:
  Algo.cfg_elim(c)

def emit_phase(+name: String, +ms: Nat, +total: Nat) -> IO(Unit):
  IO.print(
    "# phase " ++ name ++ " ms=" ++ Nat.show(ms) ++ " pct=" ++ Nat.show(pct(ms, total))
  )

def emit_buckets(+b: Buckets, +wall: Nat) -> IO(Unit):
  +total = bucket_sum(b)
  do IO<Unit>:
    IO.print("# now_unit=ms")
    IO.print("# profile_sum_ms=" ++ Nat.show(total))
    IO.print("# profile_wall_ms=" ++ Nat.show(wall))
    emit_phase("init_pop", bk_init(b), total)
    emit_phase("evaluate", bk_eval(b), total)
    emit_phase("nds_select", bk_nds_sel(b), total)
    emit_phase("nds_prepare", bk_nds_prep(b), total)
    emit_phase("nds_final", bk_nds_fin(b), total)
    emit_phase("nds", nds_all(b), total)
    emit_phase("normalize_select", bk_norm_sel(b), total)
    emit_phase("normalize_prepare", bk_norm_prep(b), total)
    emit_phase("normalize", norm_all(b), total)
    emit_phase("associate_select", bk_asg_sel(b), total)
    emit_phase("associate_prepare", bk_asg_prep(b), total)
    emit_phase("associate", asg_all(b), total)
    emit_phase("niche", bk_niche(b), total)
    emit_phase("tournament", bk_tour(b), total)
    emit_phase("offspring_sbx_pm_g12", bk_offs(b), total)
    IO.print("# phase unaccounted ms=" ++ Nat.show(Nat.sub(wall, total)) ++ " (wall minus sum)")
    return Unit{}

type NF is Data:
  NF{
    st: Norm.State
    F: List<&2, List<&2, F32>>
  }

type IR is Data:
  IR{
    idxs: List<&2, Nat>
    rng: Rng.State
  }

type Trip is Data:
  Trip{
    rng: Rng.State
    xs: List<&2, Ind.Individual>
  }

def nf_of(pair: Norm.State & List<&2, List<&2, F32>>) -> NF:
  (st, F) = pair
  NF{st, F}

def nf_st(+nf: NF) -> Norm.State:
  match nf:
    case NF{st, F}:
      st

def nf_F(+nf: NF) -> List<&2, List<&2, F32>>:
  match nf:
    case NF{st, F}:
      F

def ir_of(pair: List<&2, Nat> & Rng.State) -> IR:
  (idxs, rng) = pair
  IR{idxs, rng}

def ir_idxs(+ir: IR) -> List<&2, Nat>:
  match ir:
    case IR{idxs, rng}:
      idxs

def ir_rng(+ir: IR) -> Rng.State:
  match ir:
    case IR{idxs, rng}:
      rng

def trip_of(pair: Rng.State & List<&2, Ind.Individual>) -> Trip:
  (rng, xs) = pair
  Trip{rng, xs}

def trip_rng(+t: Trip) -> Rng.State:
  match t:
    case Trip{rng, xs}:
      rng

def trip_xs(+t: Trip) -> List<&2, Ind.Individual>:
  match t:
    case Trip{rng, xs}:
      xs

# Mirrors Surv.select_st.big + size_lock + gather, with clocks.
def select_big.fin(
  +pop: List<&2, Ind.Individual>,
  +st: Norm.State,
  +acc: Buckets,
  +t0: Nat,
  +t1: Nat,
  +t2: Nat,
  +t3: Nat,
  +t4: Nat,
  pair_i: List<&2, Nat> & Rng.State
) -> Sel:
  +ir = ir_of(pair_i)
  Sel{
    st,
    Surv.gather(pop, ir_idxs(ir)),
    ir_rng(ir),
    add_niche(
      add_asg_sel(add_norm_sel(add_nds_sel(acc, elapsed(t0, t1)), elapsed(t1, t2)), elapsed(t2, t3)),
      elapsed(t3, t4)
    )
  }

def select_big.after_asgs(
  +pop: List<&2, Ind.Individual>,
  +target: Nat,
  +dirs: List<&2, List<&2, F32>>,
  rng: Rng.State,
  +acc: Buckets,
  +t0: Nat,
  +t1: Nat,
  +t2: Nat,
  +t3: Nat,
  +fronts: List<&2, List<&2, Nat>>,
  +nf: NF,
  +asgs: List<&2, Surv.Assignment>
) -> IO(Sel):
  +n = Util.list_len(Ind.Individual, pop)
  +want = Util.nat_min(target, n)
  do IO<Sel>:
    pair_i : List<&2, Nat> & Rng.State = Surv.size_lock.rng(
      want,
      n,
      Surv.fill.wrap.rng(fronts, target, asgs, Util.list_len(List<&2, F32>, dirs), rng)
    )
    t4 : Nat <- IO.now()
    return select_big.fin(pop, nf_st(nf), acc, t0, t1, t2, t3, t4, pair_i)

def select_big.after_norm(
  +pop: List<&2, Ind.Individual>,
  +target: Nat,
  +dirs: List<&2, List<&2, F32>>,
  rng: Rng.State,
  +acc: Buckets,
  +t0: Nat,
  +t1: Nat,
  +t2: Nat,
  +fronts: List<&2, List<&2, Nat>>,
  +nf: NF
) -> IO(Sel):
  do IO<Sel>:
    asgs : List<&2, Surv.Assignment> = Surv.associate(pop, nf_F(nf), dirs)
    t3 : Nat <- IO.now()
    select_big.after_asgs(pop, target, dirs, rng, acc, t0, t1, t2, t3, fronts, nf, asgs)

def select_big.after_sort(
  +pop: List<&2, Ind.Individual>,
  +target: Nat,
  +dirs: List<&2, List<&2, F32>>,
  state: Norm.State,
  rng: Rng.State,
  acc: Buckets,
  +t0: Nat,
  +t1: Nat,
  +fronts: List<&2, List<&2, Nat>>
) -> IO(Sel):
  do IO<Sel>:
    pair_n : Norm.State & List<&2, List<&2, F32>> = Norm.normalize_nd(state, pop, Surv.front0(fronts))
    t2 : Nat <- IO.now()
    select_big.after_norm(pop, target, dirs, rng, acc, t0, t1, t2, fronts, nf_of(pair_n))

def select_big(
  +pop: List<&2, Ind.Individual>,
  +target: Nat,
  +dirs: List<&2, List<&2, F32>>,
  state: Norm.State,
  rng: Rng.State,
  acc: Buckets
) -> IO(Sel):
  do IO<Sel>:
    t0 : Nat <- IO.now()
    fronts : List<&2, List<&2, Nat>> = NDS.sort(pop)
    t1 : Nat <- IO.now()
    select_big.after_sort(pop, target, dirs, state, rng, acc, t0, t1, fronts)

def select_take(
  +pop: List<&2, Ind.Individual>,
  +target: Nat,
  state: Norm.State,
  rng: Rng.State,
  acc: Buckets
) -> IO(Sel):
  +n = Util.list_len(Ind.Individual, pop)
  IO.pure(
    Sel,
    Sel{
      state,
      Surv.gather(pop, Surv.size_lock(List.take(&2, Nat, List.range(n), target), Util.nat_min(target, n), n)),
      rng,
      acc
    }
  )

def select_keep(
  +pop: List<&2, Ind.Individual>,
  state: Norm.State,
  rng: Rng.State,
  acc: Buckets
) -> IO(Sel):
  IO.pure(Sel, Sel{state, pop, rng, acc})

def select_dirs(
  +pop: List<&2, Ind.Individual>,
  +target: Nat,
  +dirs: List<&2, List<&2, F32>>,
  state: Norm.State,
  rng: Rng.State,
  acc: Buckets,
  empty_dirs: Bool
) -> IO(Sel):
  match empty_dirs:
    case True{}:
      select_take(pop, target, state, rng, acc)
    case False{}:
      select_big(pop, target, dirs, state, rng, acc)

def select_st_timed.by(
  +pop: List<&2, Ind.Individual>,
  +target: Nat,
  +dirs: List<&2, List<&2, F32>>,
  state: Norm.State,
  rng: Rng.State,
  acc: Buckets,
  small: Bool
) -> IO(Sel):
  match small:
    case True{}:
      select_keep(pop, state, rng, acc)
    case False{}:
      select_dirs(pop, target, dirs, state, rng, acc, List.is_empty(&2, List<&2, F32>, dirs))

def select_st_timed(
  +pop: List<&2, Ind.Individual>,
  +target: Nat,
  +dirs: List<&2, List<&2, F32>>,
  state: Norm.State,
  rng: Rng.State,
  acc: Buckets
) -> IO(Sel):
  +n = Util.list_len(Ind.Individual, pop)
  select_st_timed.by(pop, target, dirs, state, rng, acc, Nat.is_le(n, target))

def prepare_fin(
  +acc: Buckets,
  +t0: Nat,
  +t1: Nat,
  +t2: Nat,
  +t3: Nat,
  +pop: List<&2, Ind.Individual>,
  +dirs: List<&2, List<&2, F32>>,
  +fronts: List<&2, List<&2, Nat>>,
  +nf: NF
) -> Prep:
  +ranked = Tour.stamp_ranks(fronts, pop, 0n)
  Prep{
    nf_st(nf),
    Tour.stamp_asgs(ranked, Surv.associate(ranked, nf_F(nf), dirs)),
    add_asg_prep(add_norm_prep(add_nds_prep(acc, elapsed(t0, t1)), elapsed(t1, t2)), elapsed(t2, t3))
  }

def add_asg_dt(prep: Prep, dt: Nat) -> Prep:
  match prep:
    case Prep{st, xs, acc}:
      Prep{st, xs, add_asg_prep(acc, dt)}

def prepare_after_norm(
  +pop: List<&2, Ind.Individual>,
  +dirs: List<&2, List<&2, F32>>,
  acc: Buckets,
  +t0: Nat,
  +t1: Nat,
  +t2: Nat,
  +fronts: List<&2, List<&2, Nat>>,
  pair_n: Norm.State & List<&2, List<&2, F32>>
) -> IO(Prep):
  do IO<Prep>:
    prep : Prep = prepare_fin(acc, t0, t1, t2, t2, pop, dirs, fronts, nf_of(pair_n))
    t3 : Nat <- IO.now()
    return add_asg_dt(prep, elapsed(t2, t3))

def prepare_after_sort(
  +pop: List<&2, Ind.Individual>,
  +dirs: List<&2, List<&2, F32>>,
  state: Norm.State,
  acc: Buckets,
  +t0: Nat,
  +t1: Nat,
  +fronts: List<&2, List<&2, Nat>>
) -> IO(Prep):
  do IO<Prep>:
    pair_n : Norm.State & List<&2, List<&2, F32>> = Norm.normalize_nd(state, pop, Surv.front0(fronts))
    t2 : Nat <- IO.now()
    prepare_after_norm(pop, dirs, acc, t0, t1, t2, fronts, pair_n)

# Mirrors Tour.prepare: NDS + normalize_nd + stamp_ranks + associate + stamp_asgs.
def prepare_timed(
  +pop: List<&2, Ind.Individual>,
  +dirs: List<&2, List<&2, F32>>,
  state: Norm.State,
  acc: Buckets
) -> IO(Prep):
  do IO<Prep>:
    t0 : Nat <- IO.now()
    fronts : List<&2, List<&2, Nat>> = NDS.sort(pop)
    t1 : Nat <- IO.now()
    prepare_after_sort(pop, dirs, state, acc, t0, t1, fronts)

def step_from_prep(rng: Rng.State, prep: Prep) -> Step:
  match prep:
    case Prep{st, xs, acc}:
      Step{H{st, xs, rng}, acc}

def sel_to_prep(+prob: Prob.Problem, +cfg: Algo.Config, sel: Sel) -> IO(Step):
  match sel:
    case Sel{st, xs, rng, acc}:
      do IO<Step>:
        prep : Prep <- prepare_timed(xs, cfg_dirs(cfg), st, acc)
        return step_from_prep(rng, prep)

def one_gen.sel(
  +prob: Prob.Problem,
  +cfg: Algo.Config,
  +pop: List<&2, Ind.Individual>,
  +state: Norm.State,
  +acc: Buckets,
  trip: Rng.State & List<&2, Ind.Individual>
) -> IO(Step):
  +tp = trip_of(trip)
  do IO<Step>:
    t0 : Nat <- IO.now()
    ev : List<&2, Ind.Individual> = Prob.evaluate_all(prob, trip_xs(tp))
    t1 : Nat <- IO.now()
    sel : Sel <- select_st_timed(
      List.append(&2, Ind.Individual, pop, ev),
      cfg_pop(cfg),
      cfg_dirs(cfg),
      state,
      trip_rng(tp),
      add_eval(acc, elapsed(t0, t1))
    )
    sel_to_prep(prob, cfg, sel)

def one_gen.offs(
  +prob: Prob.Problem,
  +cfg: Algo.Config,
  +pop: List<&2, Ind.Individual>,
  +state: Norm.State,
  +acc: Buckets,
  trip: Rng.State & List<&2, Ind.Individual>
) -> IO(Step):
  +tp = trip_of(trip)
  do IO<Step>:
    t0 : Nat <- IO.now()
    pair : Rng.State & List<&2, Ind.Individual> = Algo.create_offspring(
      prob,
      trip_xs(tp),
      cfg_pop(cfg),
      trip_rng(tp),
      cfg_elim(cfg)
    )
    t1 : Nat <- IO.now()
    one_gen.sel(prob, cfg, pop, state, add_offs(acc, elapsed(t0, t1)), pair)

def one_gen_timed(+prob: Prob.Problem, +cfg: Algo.Config, hold: Hold, acc: Buckets) -> IO(Step):
  match hold:
    case H{st, +xs, rng}:
      do IO<Step>:
        t0 : Nat <- IO.now()
        trip : Rng.State & List<&2, Ind.Individual> = Tour.select_parents(
          cfg_mode(cfg),
          xs,
          cfg_pop(cfg),
          rng
        )
        t1 : Nat <- IO.now()
        one_gen.offs(prob, cfg, xs, st, add_tour(acc, elapsed(t0, t1)), trip)

def gen_loop(fuel: Nat, step: Step, +prob: Prob.Problem, +cfg: Algo.Config) -> IO(Step):
  match fuel step:
    case 0n s:
      IO.pure(Step, s)
    case 1n+g Step{hold, acc}:
      do IO<Step>:
        nxt : Step <- one_gen_timed(prob, cfg, hold, acc)
        gen_loop(g, nxt, prob, cfg)

def hold_xs(hold: Hold) -> List<&2, Ind.Individual>:
  match hold:
    case H{st, xs, rng}:
      xs

def front_from_step(step: Step, +t0: Nat, +t1: Nat) -> Front:
  match step:
    case Step{hold, acc}:
      Front{Algo.nd_front(hold_xs(hold)), add_nds_fin(acc, elapsed(t0, t1))}

def run_after.looped(+t0: Nat, step: Step) -> IO(Front):
  do IO<Front>:
    t1 : Nat <- IO.now()
    return front_from_step(step, t0, t1)

def run_after(
  +prob: Prob.Problem,
  +cfg: Algo.Config,
  rng: Rng.State,
  prep: Prep
) -> IO(Front):
  match prep:
    case Prep{st, pop, acc}:
      do IO<Front>:
        looped : Step <- gen_loop(cfg_gens(cfg), Step{H{st, pop, rng}, acc}, prob, cfg)
        t0 : Nat <- IO.now()
        run_after.looped(t0, looped)

def run_go(
  +prob: Prob.Problem,
  +cfg: Algo.Config,
  acc: Buckets,
  trip: Rng.State & List<&2, Ind.Individual>
) -> IO(Front):
  +tp = trip_of(trip)
  do IO<Front>:
    t0 : Nat <- IO.now()
    ev : List<&2, Ind.Individual> = Prob.evaluate_all(prob, trip_xs(tp))
    t1 : Nat <- IO.now()
    prep : Prep <- prepare_timed(
      ev,
      cfg_dirs(cfg),
      Norm.new_state(Prob.n_obj(prob)),
      add_eval(acc, elapsed(t0, t1))
    )
    run_after(prob, cfg, trip_rng(tp), prep)

def run_sized(+prob: Prob.Problem, +cfg: Algo.Config, n: Nat) -> IO(Front):
  match n:
    case 0n:
      IO.pure(Front, Front{Nil{}, zero()})
    case 1n+p:
      do IO<Front>:
        t0 : Nat <- IO.now()
        pair : Rng.State & List<&2, Ind.Individual> = Algo.init_pop(prob, 1n+p, Rng.from_nat(cfg_seed(cfg)))
        t1 : Nat <- IO.now()
        run_go(prob, cfg, add_init(zero(), elapsed(t0, t1)), pair)

def pad_front(+n: Nat, front: Front) -> Front:
  match front:
    case Front{xs, acc}:
      Front{Util.list_take_pad(Ind.Individual, Ind.from_objectives(Nil{}), xs, n), acc}

def run_profile(+prob: Prob.Problem, +cfg: Algo.Config) -> IO(Front):
  +n = cfg_pop(cfg)
  do IO<Front>:
    raw : Front <- run_sized(prob, cfg, n)
    return pad_front(n, raw)

def emit_front_of(front: Front, +wall: Nat, +label: String, +n_obj: Nat, +partitions: Nat, +cfg: Algo.Config) -> IO(Unit):
  match front:
    case Front{xs, acc}:
      do IO<Unit>:
        IO.print(
          "# profile: " ++ label
          ++ " n_obj=" ++ Nat.show(n_obj)
          ++ " partitions=" ++ Nat.show(partitions)
          ++ " pop=" ++ Nat.show(cfg_pop(cfg))
          ++ " gens=" ++ Nat.show(cfg_gens(cfg))
          ++ " seed=" ++ Nat.show(cfg_seed(cfg))
          ++ " tournament=PymooCompatible"
        )
        emit_buckets(acc, wall)
        Algo.emit_front(xs)

def run_and_emit(
  +prob: Prob.Problem,
  +cfg: Algo.Config,
  +label: String,
  +n_obj: Nat,
  +partitions: Nat
) -> IO(Unit):
  do IO<Unit>:
    t0 : Nat <- IO.now()
    front : Front <- run_profile(prob, cfg)
    t1 : Nat <- IO.now()
    emit_front_of(front, elapsed(t0, t1), label, n_obj, partitions, cfg)
