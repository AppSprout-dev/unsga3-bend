# Isolated associate map used by the Metal-kernel experiment.
# Calls Surv.nearest_one (the product perp + argmin) over generated points.
# Not imported by src/algorithm.bend / Run.
import Base
import ../../src/survival.bend as Surv
import ../../src/util.bend as Util

def lcg(s: U32) -> U32:
  U32.add(U32.mul(s, U32.from_nat(1664525n)), U32.from_nat(1013904223n))

def u32_to_unit(s: U32) -> F32:
  F32.div(F32.from_nat(U32.to_nat(U32.shrn(s, 8n))), 16777216.0)

def skip_lcg(fuel: Nat, s: U32) -> U32:
  match fuel:
    case 0n:
      s
    case 1n+k:
      skip_lcg(k, lcg(s))

def gen_vec.cons(+s2: U32, pair: List<&2, F32> & U32) -> List<&2, F32> & U32:
  (xs, s3) = pair
  (u32_to_unit(s2) <> xs, s3)

def gen_vec(fuel: Nat, s: U32) -> List<&2, F32> & U32:
  match fuel:
    case 0n:
      (Nil{}, s)
    case 1n+k:
      +s2 = lcg(s)
      gen_vec.cons(s2, gen_vec(k, s2))

def gen_mat.join(pair_vec: List<&2, F32> & U32, pair_rest: List<&2, List<&2, F32>> & U32) -> List<&2, List<&2, F32>> & U32:
  (v, s2) = pair_vec
  (vs, s3) = pair_rest
  (v <> vs, s3)

def gen_mat(rows: Nat, +cols: Nat, +s: U32) -> List<&2, List<&2, F32>> & U32:
  match rows:
    case 0n:
      (Nil{}, s)
    case 1n+k:
      gen_mat.join(gen_vec(cols, s), gen_mat(k, cols, skip_lcg(cols, s)))

def map_nearest.go(+dirs: List<&2, List<&2, F32>>, +fuel: Nat, pts: List<&2, List<&2, F32>>) -> List<&2, Surv.Assignment>:
  match fuel pts:
    case 0n Nil{}:
      Nil{}
    case 0n p <> rest:
      Surv.nearest_one(p, dirs) <> map_nearest.go(dirs, 0n, rest)
    case 1n+p Nil{}:
      Nil{}
    case 1n+p h <> Nil{}:
      Surv.nearest_one(h, dirs) <> Nil{}
    case 1n+p h <> t:
      +all = {h <> t : List<&2, List<&2, F32>>}
      +mid = Nat.div(Util.list_len(List<&2, F32>, all), 2n)
      lo hi = map_nearest.go(dirs, p, List.take(&2, List<&2, F32>, all, mid)) map_nearest.go(dirs, p, List.drop(&2, List<&2, F32>, all, mid))
      List.append(&2, Surv.Assignment, lo, hi)

def map_nearest(+pts: List<&2, List<&2, F32>>, +dirs: List<&2, List<&2, F32>>) -> List<&2, Surv.Assignment>:
  map_nearest.go(dirs, Util.list_len(List<&2, F32>, pts), pts)

def map_nearest_bang(+pts: List<&2, List<&2, F32>>, +dirs: List<&2, List<&2, F32>>) -> List<&2, Surv.Assignment>:
  map_nearest.go!(dirs, Util.list_len(List<&2, F32>, pts), pts)

def repeat.once(+bang: Bool, +pts: List<&2, List<&2, F32>>, +dirs: List<&2, List<&2, F32>>) -> List<&2, Surv.Assignment>:
  match bang:
    case True{}:
      map_nearest_bang(pts, dirs)
    case False{}:
      map_nearest(pts, dirs)

def sum_idx(asgs: List<&2, Surv.Assignment>) -> Nat:
  match asgs:
    case Nil{}:
      0n
    case a <> rest:
      Nat.add(Surv.asg_ref(a), sum_idx(rest))

def repeat.use(+asgs: List<&2, Surv.Assignment>) -> List<&2, Surv.Assignment> & Nat:
  (asgs, sum_idx(asgs))

def repeat.join(+asgs: List<&2, Surv.Assignment>, pair: List<&2, Surv.Assignment> & Nat) -> List<&2, Surv.Assignment> & Nat:
  (rest_asgs, rest_acc) = pair
  (rest_asgs, Nat.add(sum_idx(asgs), rest_acc))

# Each iteration's assignments are folded into acc so the compiler cannot
# drop repeated maps as unused. acc must equal reps * sum_idx(last).
def repeat(+fuel: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, +dirs: List<&2, List<&2, F32>>) -> List<&2, Surv.Assignment> & Nat:
  match fuel:
    case 0n:
      (Nil{}, 0n)
    case 1n:
      repeat.use(repeat.once(bang, pts, dirs))
    case 1n+k:
      repeat.join(repeat.once(bang, pts, dirs), repeat(k, bang, pts, dirs))

def warmup_repeat(+fuel: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, +dirs: List<&2, List<&2, F32>>) -> List<&2, Surv.Assignment>:
  match fuel:
    case 0n:
      Nil{}
    case _:
      repeat.once(bang, pts, dirs)


def hist.go(asgs: List<&2, Surv.Assignment>, acc: List<&2, Nat>) -> List<&2, Nat>:
  match asgs:
    case Nil{}:
      acc
    case a <> rest:
      hist.go(rest, Util.inc_at(acc, Surv.asg_ref(a)))

def hist(+asgs: List<&2, Surv.Assignment>, +nref: Nat) -> List<&2, Nat>:
  hist.go(asgs, Util.zeros_nat(nref))

def sum_nats(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case x <> rest:
      Nat.add(x, sum_nats(rest))

def show_asgs(asgs: List<&2, Surv.Assignment>) -> IO(Unit):
  match asgs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case +a <> rest:
      do IO<Unit>:
        IO.print(Nat.show(Surv.asg_ref(a)) ++ " " ++ F32.show(Surv.asg_dist(a)))
        show_asgs(rest)

def show_counts.go(xs: List<&2, Nat>, acc: String) -> String:
  match xs:
    case Nil{}:
      acc
    case x <> Nil{}:
      acc ++ Nat.show(x)
    case x <> rest:
      show_counts.go(rest, acc ++ Nat.show(x) ++ " ")

def show_counts(xs: List<&2, Nat>) -> IO(Unit):
  IO.print(show_counts.go(xs, ""))

def run.dump(+dump: Nat, +asgs: List<&2, Surv.Assignment>, +counts: List<&2, Nat>) -> IO(Unit):
  match dump:
    case 0n:
      IO.pure(Unit, Unit{})
    case _:
      do IO<Unit>:
        IO.print("ASSIGNMENTS")
        show_asgs(asgs)
        IO.print("COUNTS")
        show_counts(counts)

def run.report(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +keep: Nat,
  +elapsed: Nat,
  +acc: Nat,
  +asgs: List<&2, Surv.Assignment>,
  +counts: List<&2, Nat>
) -> IO(Unit):
  do IO<Unit>:
    IO.print("kind=" ++ Bool.pick(String, bang, "bend_bang", "bend_product"))
    IO.print(
      "n=" ++ Nat.show(n)
      ++ " r=" ++ Nat.show(r)
      ++ " m=" ++ Nat.show(m)
      ++ " seed=" ++ Nat.show(seed)
      ++ " keep=" ++ Nat.show(keep)
    )
    IO.print("warmup=" ++ Nat.show(warmup) ++ " reps=" ++ Nat.show(reps))
    IO.print("total_ms=" ++ Nat.show(elapsed))
    IO.print("sum_idx=" ++ Nat.show(sum_idx(asgs)))
    IO.print("sum_idx_acc=" ++ Nat.show(acc))
    IO.print("n_asg=" ++ Nat.show(Util.list_len(Surv.Assignment, asgs)))
    IO.print("counts_sum=" ++ Nat.show(sum_nats(counts)))
    run.dump(dump, asgs, counts)

def run.after_time(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +keep: Nat,
  +t0: Nat,
  +t1: Nat,
  +acc: Nat,
  +asgs: List<&2, Surv.Assignment>
) -> IO(Unit):
  run.report(n, r, m, seed, warmup, reps, dump, bang, keep, Nat.sub(t1, t0), acc, asgs, hist(asgs, r))

def run.after_pair(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +keep: Nat,
  +t0: Nat,
  +t1: Nat,
  pair: List<&2, Surv.Assignment> & Nat
) -> IO(Unit):
  (asgs, acc) = pair
  run.after_time(n, r, m, seed, warmup, reps, dump, bang, keep, t0, t1, acc, asgs)

def run.emit(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +pts: List<&2, List<&2, F32>>,
  +dirs: List<&2, List<&2, F32>>
) -> IO(Unit):
  do IO<Unit>:
    w : List<&2, Surv.Assignment> = warmup_repeat(warmup, bang, pts, dirs)
    keep : Nat = Util.list_len(Surv.Assignment, w)
    t0 : Nat <- IO.now()
    pair : List<&2, Surv.Assignment> & Nat = repeat(reps, bang, pts, dirs)
    t1 : Nat <- IO.now()
    run.after_pair(n, r, m, seed, warmup, reps, dump, bang, keep, t0, t1, pair)


def run.after_dirs(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +pts: List<&2, List<&2, F32>>,
  pair: List<&2, List<&2, F32>> & U32
) -> IO(Unit):
  (dirs, s2) = pair
  run.emit(n, r, m, seed, warmup, reps, dump, bang, pts, dirs)

def run.after_pts(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  pair: List<&2, List<&2, F32>> & U32
) -> IO(Unit):
  (pts, s1) = pair
  run.after_dirs(n, r, m, seed, warmup, reps, dump, bang, pts, gen_mat(r, m, s1))

def run(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool
) -> IO(Unit):
  run.after_pts(n, r, m, seed, warmup, reps, dump, bang, gen_mat(n, m, U32.from_nat(seed)))

