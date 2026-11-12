# Isolated Array.clone / Array.fork associate map, for the #1376 suggestion.
# Each leaf handles `chunk` points and clones or forks the packed refs once.
# Not imported by src/algorithm.bend / Run.

import Base
import ../../src/survival.bend as Surv
import ../../src/util.bend as Util
import ./assoc_map.bend as M

def consume_arr.join(+u: Unit, +v: Unit) -> Unit:
  Unit{}

def consume_arr(a: Array<F32>) -> Unit:
  match a:
    case ALeaf{+x}:
      Unit{}
    case ANode{xs, ys}:
      consume_arr.join(consume_arr(xs), consume_arr(ys))

def flatten_rows(rows: List<&2, List<&2, F32>>) -> List<&2, F32>:
  match rows:
    case Nil{}:
      Nil{}
    case row <> rest:
      List.append(&2, F32, row, flatten_rows(rest))

def depth_for.go(+need: Nat, fuel: Nat, +d: Nat, +cap: Nat) -> Nat:
  match fuel:
    case 0n:
      d
    case 1n+p:
      Bool.pick(Nat, Nat.is_lt(cap, need), depth_for.go(need, p, Nat.add(d, 1n), Nat.add(cap, cap)), d)

def depth_for(need: Nat) -> Nat:
  depth_for.go(Nat.max(need, 1n), 40n, 0n, 1n)

def fill_from(xs: List<&2, F32>, arr: Array<F32>, +i: Nat) -> Array<F32>:
  match xs:
    case Nil{}:
      arr
    case x <> rest:
      fill_from(rest, Array.set(F32, arr, U32.from_nat(i), x), Nat.add(i, 1n))

def pack_dirs(dirs: List<&2, List<&2, F32>>) -> Array<F32>:
  +flat = flatten_rows(dirs)
  +need = Util.list_len(F32, flat)
  fill_from(flat, Array.new(F32, depth_for(need), 0.0), 0n)

def pick_pack.choose(+kind: Nat, +dirs_list: List<&2, List<&2, F32>>, is_list: Bool) -> Array<F32>:
  match is_list:
    case True{}:
      Array.new(F32, 0n, 0.0)
    case False{}:
      pack_dirs(dirs_list)

def pick_pack(+kind: Nat, +dirs_list: List<&2, List<&2, F32>>) -> Array<F32>:
  pick_pack.choose(kind, dirs_list, Nat.is_eq(kind, 0n))

def dot_slice.add(+x: F32, +y: F32, pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs2, rest) = pair
  (dirs2, F32.add(F32.mul(x, y), rest))

def dot_slice.got(+x: F32, rec: Array<F32> -> (Array<F32> & F32), pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs1, y) = pair
  dot_slice.add(x, y, rec(dirs1))

def dot_slice(f: List<&2, F32>, dirs: Array<F32>, +base: Nat) -> Array<F32> & F32:
  match f:
    case Nil{}:
      (dirs, 0.0)
    case x <> xs:
      dot_slice.got(x, (d => dot_slice(xs, d, Nat.add(base, 1n))), Array.get(F32, dirs, U32.from_nat(base)))

def resid_slice.add(+rad: F32, pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs2, rest) = pair
  (dirs2, F32.add(F32.mul(rad, rad), rest))

def resid_slice.got(+t: F32, +x: F32, rec: Array<F32> -> (Array<F32> & F32), pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs1, y) = pair
  +rad = F32.sub(x, F32.mul(t, y))
  resid_slice.add(rad, rec(dirs1))

def resid_slice(+t: F32, f: List<&2, F32>, dirs: Array<F32>, +base: Nat) -> Array<F32> & F32:
  match f:
    case Nil{}:
      (dirs, 0.0)
    case x <> xs:
      resid_slice.got(t, x, (d => resid_slice(t, xs, d, Nat.add(base, 1n))), Array.get(F32, dirs, U32.from_nat(base)))

def sqnorm_slice.add(+y: F32, pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs2, rest) = pair
  (dirs2, F32.add(F32.mul(y, y), rest))

def sqnorm_slice.got(rec: Array<F32> -> (Array<F32> & F32), pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs1, y) = pair
  sqnorm_slice.add(y, rec(dirs1))

def sqnorm_slice(fuel: Nat, dirs: Array<F32>, +base: Nat) -> Array<F32> & F32:
  match fuel:
    case 0n:
      (dirs, 0.0)
    case 1n+k:
      sqnorm_slice.got((d => sqnorm_slice(k, d, Nat.add(base, 1n))), Array.get(F32, dirs, U32.from_nat(base)))

def perp_arr.fin(pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs2, rs) = pair
  (dirs2, F32.sqrt(rs))

def perp_arr.after_dot(+f: List<&2, F32>, +base: Nat, +ww: F32, pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs1, fw) = pair
  +t = F32.div(fw, ww)
  perp_arr.fin(resid_slice(t, f, dirs1, base))

def perp_arr.big(+f: List<&2, F32>, dirs: Array<F32>, +base: Nat, +ww: F32) -> Array<F32> & F32:
  perp_arr.after_dot(f, base, ww, dot_slice(f, dirs, base))

def perp_arr.pick(+f: List<&2, F32>, dirs: Array<F32>, +base: Nat, +m: Nat, +ww: F32, tiny: Bool) -> Array<F32> & F32:
  match tiny:
    case True{}:
      (dirs, F32.sqrt(Util.vec_sqnorm(f)))
    case False{}:
      perp_arr.big(f, dirs, base, ww)

def perp_arr.after_ww2(+f: List<&2, F32>, +base: Nat, +m: Nat, dirs1: Array<F32>, +ww: F32) -> Array<F32> & F32:
  perp_arr.pick(f, dirs1, base, m, ww, F32.is_lt(ww, 0.0000000000000001))

def perp_arr.after_ww(+f: List<&2, F32>, +base: Nat, +m: Nat, pair: Array<F32> & F32) -> Array<F32> & F32:
  (dirs1, ww) = pair
  perp_arr.after_ww2(f, base, m, dirs1, ww)

def perp_arr(+f: List<&2, F32>, dirs: Array<F32>, +base: Nat, +m: Nat) -> Array<F32> & F32:
  perp_arr.after_ww(f, base, m, sqnorm_slice(m, dirs, base))

def nearest_go_arr.cont(+i: Nat, +best_i: Nat, +best_d: F32, rec: Array<F32> -> F32 -> (Array<F32> & Nat), pair: Array<F32> & F32) -> Array<F32> & Nat:
  (dirs2, d) = pair
  rec(dirs2, d)

def nearest_go_arr(remaining: Nat, +f: List<&2, F32>, dirs: Array<F32>, +m: Nat, +i: Nat, +best_i: Nat, +best_d: F32) -> Array<F32> & Nat:
  match remaining:
    case 0n:
      (dirs, best_i)
    case 1n+k:
      nearest_go_arr.cont(
        i,
        best_i,
        best_d,
        (dirs2 => (+d => nearest_go_arr(
          k,
          f,
          dirs2,
          m,
          Nat.add(i, 1n),
          Bool.pick(Nat, F32.is_lt(d, best_d), i, best_i),
          Bool.pick(F32, F32.is_lt(d, best_d), d, best_d)
        ))),
        perp_arr(f, dirs, Nat.mul(i, m), m)
      )

def nearest_arr(+f: List<&2, F32>, dirs: Array<F32>, +m: Nat, +r: Nat) -> Array<F32> & Nat:
  nearest_go_arr(r, f, dirs, m, 0n, 0n, 1000000000.0)

def seq_pts.cons(+idx: Nat, pair: List<&2, Nat> & Array<F32>) -> List<&2, Nat> & Array<F32>:
  (rest_idxs, dirs3) = pair
  (idx <> rest_idxs, dirs3)

def seq_pts.got(rec: Array<F32> -> (List<&2, Nat> & Array<F32>), pair: Array<F32> & Nat) -> List<&2, Nat> & Array<F32>:
  (dirs2, idx) = pair
  seq_pts.cons(idx, rec(dirs2))

def seq_pts(pts: List<&2, List<&2, F32>>, +m: Nat, +r: Nat, dirs: Array<F32>) -> List<&2, Nat> & Array<F32>:
  match pts:
    case Nil{}:
      (Nil{}, dirs)
    case +p <> rest:
      seq_pts.got((d => seq_pts(rest, m, r, d)), nearest_arr(p, dirs, m, r))

def map_clone.seq_end.emit(+idxs: List<&2, Nat>, u: Unit) -> List<&2, Nat>:
  idxs

def map_clone.seq_end.consume(pair: List<&2, Nat> & Array<F32>) -> List<&2, Nat>:
  (idxs, dirs2) = pair
  map_clone.seq_end.emit(idxs, consume_arr(dirs2))

def map_clone.seq_end(+m: Nat, +r: Nat, dirs: Array<F32>, pts: List<&2, List<&2, F32>>) -> List<&2, Nat>:
  map_clone.seq_end.consume(seq_pts(pts, m, r, dirs))

def map_clone.after_clone(rec_lo: Array<F32> -> List<&2, Nat>, rec_hi: Array<F32> -> List<&2, Nat>, pair: Array<F32> & Array<F32>) -> List<&2, Nat>:
  (d1, d2) = pair
  lo hi = rec_lo(d1) rec_hi(d2)
  List.append(&2, Nat, lo, hi)

def map_clone.go(+m: Nat, +r: Nat, +chunk: Nat, +fuel: Nat, dirs: Array<F32>, +pts: List<&2, List<&2, F32>>, split: Bool) -> List<&2, Nat>:
  match fuel split:
    case 0n True{}:
      map_clone.seq_end(m, r, dirs, pts)
    case 0n False{}:
      map_clone.seq_end(m, r, dirs, pts)
    case 1n+p False{}:
      map_clone.seq_end(m, r, dirs, pts)
    case 1n+p True{}:
      +n = Util.list_len(List<&2, F32>, pts)
      +c = Nat.max(chunk, 1n)
      +mid = Nat.div(n, 2n)
      map_clone.after_clone(
        (d1 => map_clone.go(m, r, chunk, p, d1, List.take(&2, List<&2, F32>, pts, mid), Nat.is_gt(mid, c))),
        (d2 => map_clone.go(m, r, chunk, p, d2, List.drop(&2, List<&2, F32>, pts, mid), Nat.is_gt(Nat.sub(n, mid), c))),
        Array.clone(F32, dirs)
      )

def map_fork.join(pair_lo: List<&2, Nat> & Array<F32>, pair_hi: List<&2, Nat> & Array<F32>) -> List<&2, Nat> & Array<F32>:
  (lo, a1) = pair_lo
  (hi, a2) = pair_hi
  (List.append(&2, Nat, lo, hi), Array.join(F32, a1, a2))

def map_fork.after_fork(rec_lo: Array<F32> -> (List<&2, Nat> & Array<F32>), rec_hi: Array<F32> -> (List<&2, Nat> & Array<F32>), pair: Array<F32> & Array<F32>) -> List<&2, Nat> & Array<F32>:
  (d1, d2) = pair
  map_fork.join(rec_lo(d1), rec_hi(d2))

def map_fork.go(+m: Nat, +r: Nat, +chunk: Nat, +fuel: Nat, dirs: Array<F32>, +pts: List<&2, List<&2, F32>>, split: Bool) -> List<&2, Nat> & Array<F32>:
  match fuel split:
    case 0n True{}:
      seq_pts(pts, m, r, dirs)
    case 0n False{}:
      seq_pts(pts, m, r, dirs)
    case 1n+p False{}:
      seq_pts(pts, m, r, dirs)
    case 1n+p True{}:
      +n = Util.list_len(List<&2, F32>, pts)
      +c = Nat.max(chunk, 1n)
      +mid = Nat.div(n, 2n)
      map_fork.after_fork(
        (d1 => map_fork.go(m, r, chunk, p, d1, List.take(&2, List<&2, F32>, pts, mid), Nat.is_gt(mid, c))),
        (d2 => map_fork.go(m, r, chunk, p, d2, List.drop(&2, List<&2, F32>, pts, mid), Nat.is_gt(Nat.sub(n, mid), c))),
        Array.fork(F32, dirs)
      )

def idxs_of(asgs: List<&2, Surv.Assignment>) -> List<&2, Nat>:
  match asgs:
    case Nil{}:
      Nil{}
    case +a <> rest:
      Surv.asg_ref(a) <> idxs_of(rest)

def once.list.run(+bang: Bool, +pts: List<&2, List<&2, F32>>, +dirs_list: List<&2, List<&2, F32>>) -> List<&2, Surv.Assignment>:
  match bang:
    case True{}:
      M.map_nearest_bang(pts, dirs_list)
    case False{}:
      M.map_nearest(pts, dirs_list)

def once.list(+bang: Bool, +pts: List<&2, List<&2, F32>>, +dirs_list: List<&2, List<&2, F32>>, dirs_arr: Array<F32>) -> List<&2, Nat> & Array<F32>:
  (idxs_of(once.list.run(bang, pts, dirs_list)), dirs_arr)

def once.clone.run(+m: Nat, +r: Nat, +chunk: Nat, bang: Bool, +pts: List<&2, List<&2, F32>>, dirs: Array<F32>) -> List<&2, Nat>:
  match bang:
    case True{}:
      map_clone.go!(m, r, chunk, Util.list_len(List<&2, F32>, pts), dirs, pts, Nat.is_gt(Util.list_len(List<&2, F32>, pts), Nat.max(chunk, 1n)))
    case False{}:
      map_clone.go(m, r, chunk, Util.list_len(List<&2, F32>, pts), dirs, pts, Nat.is_gt(Util.list_len(List<&2, F32>, pts), Nat.max(chunk, 1n)))

def once.clone.after(+m: Nat, +r: Nat, +chunk: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, pair: Array<F32> & Array<F32>) -> List<&2, Nat> & Array<F32>:
  (keep, use) = pair
  (once.clone.run(m, r, chunk, bang, pts, use), keep)

def once.clone(+m: Nat, +r: Nat, +chunk: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, dirs: Array<F32>) -> List<&2, Nat> & Array<F32>:
  once.clone.after(m, r, chunk, bang, pts, Array.clone(F32, dirs))

def once.fork.run(+m: Nat, +r: Nat, +chunk: Nat, bang: Bool, +pts: List<&2, List<&2, F32>>, dirs: Array<F32>) -> List<&2, Nat> & Array<F32>:
  match bang:
    case True{}:
      map_fork.go!(m, r, chunk, Util.list_len(List<&2, F32>, pts), dirs, pts, Nat.is_gt(Util.list_len(List<&2, F32>, pts), Nat.max(chunk, 1n)))
    case False{}:
      map_fork.go(m, r, chunk, Util.list_len(List<&2, F32>, pts), dirs, pts, Nat.is_gt(Util.list_len(List<&2, F32>, pts), Nat.max(chunk, 1n)))

def once.fork.finish(keep: Array<F32>, pair: List<&2, Nat> & Array<F32>) -> List<&2, Nat> & Array<F32>:
  (asgs, use2) = pair
  (asgs, Array.join(F32, keep, use2))

def once.fork.after(+m: Nat, +r: Nat, +chunk: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, pair: Array<F32> & Array<F32>) -> List<&2, Nat> & Array<F32>:
  (keep, use) = pair
  once.fork.finish(keep, once.fork.run(m, r, chunk, bang, pts, use))

def once.fork(+m: Nat, +r: Nat, +chunk: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, dirs: Array<F32>) -> List<&2, Nat> & Array<F32>:
  once.fork.after(m, r, chunk, bang, pts, Array.fork(F32, dirs))

def once(+kind: Nat, +m: Nat, +r: Nat, +chunk: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, +dirs_list: List<&2, List<&2, F32>>, dirs_arr: Array<F32>) -> List<&2, Nat> & Array<F32>:
  match kind:
    case 0n:
      once.list(bang, pts, dirs_list, dirs_arr)
    case 1n:
      once.clone(m, r, chunk, bang, pts, dirs_arr)
    case _:
      once.fork(m, r, chunk, bang, pts, dirs_arr)

def sum_nats(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case x <> rest:
      Nat.add(x, sum_nats(rest))

def same_nats(a: List<&2, Nat>, b: List<&2, Nat>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case +x <> xs +y <> ys:
      Bool.and(Nat.is_eq(x, y), same_nats(xs, ys))
    case Nil{} y <> ys:
      False{}
    case x <> xs Nil{}:
      False{}

def show_idxs.go(xs: List<&2, Nat>) -> IO(Unit):
  match xs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case +x <> rest:
      do IO<Unit>:
        IO.print(Nat.show(x))
        show_idxs.go(rest)

def run.dump(+dump: Nat, +idxs: List<&2, Nat>) -> IO(Unit):
  match dump:
    case 0n:
      IO.pure(Unit, Unit{})
    case _:
      do IO<Unit>:
        IO.print("INDICES")
        show_idxs.go(idxs)

def kind_name(kind: Nat) -> String:
  match kind:
    case 0n:
      "list"
    case 1n:
      "clone"
    case _:
      "fork"

def bang_name(bang: Bool) -> String:
  Bool.pick(String, bang, "1", "0")

def match_name(ok: Bool) -> String:
  Bool.pick(String, ok, "1", "0")

def repeat.use2(+idxs: List<&2, Nat>, dirs: Array<F32>) -> List<&2, Nat> & Nat & Array<F32>:
  (idxs, sum_nats(idxs), dirs)

def repeat.use(pair: List<&2, Nat> & Array<F32>) -> List<&2, Nat> & Nat & Array<F32>:
  (idxs, dirs) = pair
  repeat.use2(idxs, dirs)

def repeat.join(+idxs: List<&2, Nat>, triple: List<&2, Nat> & Nat & Array<F32>) -> List<&2, Nat> & Nat & Array<F32>:
  (rest_idxs, rest_acc, dirs) = triple
  (rest_idxs, Nat.add(sum_nats(idxs), rest_acc), dirs)

def repeat.cont(rec: Array<F32> -> (List<&2, Nat> & Nat & Array<F32>), pair: List<&2, Nat> & Array<F32>) -> List<&2, Nat> & Nat & Array<F32>:
  (idxs, dirs2) = pair
  repeat.join(idxs, rec(dirs2))

def repeat(fuel: Nat, +kind: Nat, +m: Nat, +r: Nat, +chunk: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, +dirs_list: List<&2, List<&2, F32>>, dirs_arr: Array<F32>) -> List<&2, Nat> & Nat & Array<F32>:
  match fuel:
    case 0n:
      (Nil{}, 0n, dirs_arr)
    case 1n:
      repeat.use(once(kind, m, r, chunk, bang, pts, dirs_list, dirs_arr))
    case 1n+k:
      repeat.cont((d => repeat(k, kind, m, r, chunk, bang, pts, dirs_list, d)), once(kind, m, r, chunk, bang, pts, dirs_list, dirs_arr))

def warmup_repeat(+fuel: Nat, +kind: Nat, +m: Nat, +r: Nat, +chunk: Nat, +bang: Bool, +pts: List<&2, List<&2, F32>>, +dirs_list: List<&2, List<&2, F32>>, dirs_arr: Array<F32>) -> List<&2, Nat> & Array<F32>:
  match fuel:
    case 0n:
      (Nil{}, dirs_arr)
    case _:
      once(kind, m, r, chunk, bang, pts, dirs_list, dirs_arr)

def run.report(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  +elapsed: Nat,
  +acc: Nat,
  +idxs: List<&2, Nat>,
  +ok: Bool
) -> IO(Unit):
  do IO<Unit>:
    IO.print("kind=" ++ kind_name(kind))
    IO.print("chunk=" ++ Nat.show(chunk))
    IO.print("bang=" ++ bang_name(bang))
    IO.print(
      "n=" ++ Nat.show(n)
      ++ " r=" ++ Nat.show(r)
      ++ " m=" ++ Nat.show(m)
      ++ " seed=" ++ Nat.show(seed)
    )
    IO.print("warmup=" ++ Nat.show(warmup) ++ " reps=" ++ Nat.show(reps))
    IO.print("total_ms=" ++ Nat.show(elapsed))
    IO.print("sum_idx=" ++ Nat.show(sum_nats(idxs)))
    IO.print("sum_idx_acc=" ++ Nat.show(acc))
    IO.print("n_asg=" ++ Nat.show(Util.list_len(Nat, idxs)))
    IO.print("match_list=" ++ match_name(ok))
    run.dump(dump, idxs)

def run.after_consumed(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  +t0: Nat,
  +t1: Nat,
  +acc: Nat,
  +idxs: List<&2, Nat>,
  +pts: List<&2, List<&2, F32>>,
  +dirs_list: List<&2, List<&2, F32>>,
  u: Unit
) -> IO(Unit):
  +ok = same_nats(idxs, idxs_of(M.map_nearest(pts, dirs_list)))
  run.report(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, Nat.sub(t1, t0), acc, idxs, ok)

def run.after_time(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  +t0: Nat,
  +t1: Nat,
  +acc: Nat,
  +idxs: List<&2, Nat>,
  +pts: List<&2, List<&2, F32>>,
  +dirs_list: List<&2, List<&2, F32>>,
  dirs_arr: Array<F32>
) -> IO(Unit):
  run.after_consumed(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, t0, t1, acc, idxs, pts, dirs_list, consume_arr(dirs_arr))

def run.after_triple(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  +t0: Nat,
  +t1: Nat,
  triple: List<&2, Nat> & Nat & Array<F32>,
  +pts: List<&2, List<&2, F32>>,
  +dirs_list: List<&2, List<&2, F32>>
) -> IO(Unit):
  (idxs, acc, dirs_arr) = triple
  run.after_time(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, t0, t1, acc, idxs, pts, dirs_list, dirs_arr)

def run.after_warm(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  +pts: List<&2, List<&2, F32>>,
  +dirs_list: List<&2, List<&2, F32>>,
  pair: List<&2, Nat> & Array<F32>
) -> IO(Unit):
  (w, dirs2) = pair
  +keep : Nat = Util.list_len(Nat, w)
  do IO<Unit>:
    t0 : Nat <- IO.now()
    triple : List<&2, Nat> & Nat & Array<F32> = repeat(reps, kind, m, r, chunk, bang, pts, dirs_list, dirs2)
    t1 : Nat <- IO.now()
    IO.print("keep=" ++ Nat.show(keep))
    run.after_triple(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, t0, t1, triple, pts, dirs_list)

def run.emit(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  +pts: List<&2, List<&2, F32>>,
  +dirs_list: List<&2, List<&2, F32>>,
  dirs_arr: Array<F32>
) -> IO(Unit):
  run.after_warm(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, pts, dirs_list, warmup_repeat(warmup, kind, m, r, chunk, bang, pts, dirs_list, dirs_arr))


def run.after_dirs2(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  +pts: List<&2, List<&2, F32>>,
  +dirs_list: List<&2, List<&2, F32>>
) -> IO(Unit):
  run.emit(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, pts, dirs_list, pick_pack(kind, dirs_list))

def run.after_dirs(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  +pts: List<&2, List<&2, F32>>,
  pair: List<&2, List<&2, F32>> & U32
) -> IO(Unit):
  (dirs_list, s2) = pair
  run.after_dirs2(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, pts, dirs_list)


def run.after_pts(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat,
  pair: List<&2, List<&2, F32>> & U32
) -> IO(Unit):
  (pts, s1) = pair
  run.after_dirs(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, pts, M.gen_mat(r, m, s1))

def run(
  +n: Nat,
  +r: Nat,
  +m: Nat,
  +seed: Nat,
  +warmup: Nat,
  +reps: Nat,
  +dump: Nat,
  +bang: Bool,
  +kind: Nat,
  +chunk: Nat
) -> IO(Unit):
  run.after_pts(n, r, m, seed, warmup, reps, dump, bang, kind, chunk, M.gen_mat(n, m, U32.from_nat(seed)))
