// Experimental Metal host for associate + niche_count.
// Not a product code path. Times include host<->device traffic for e2e;
// kernel-only uses MTLCommandBuffer GPU timestamps.
import Foundation
import Metal

let LCG_MUL: UInt32 = 1_664_525
let LCG_ADD: UInt32 = 1_013_904_223
let BEST_D0: Float = 1_000_000_000.0
let TINY_WW: Float = 1.0e-16
let DIST_ABS: Float = 1.0e-6
let DIST_REL: Float = 1.0e-5

func lcg(_ state: UInt32) -> UInt32 {
    return state &* LCG_MUL &+ LCG_ADD
}

func u32ToUnit(_ state: UInt32) -> Float {
    let u = (state >> 8) & 0x00FF_FFFF
    return Float(u) / 16_777_216.0
}

func genMatrix(rows: Int, cols: Int, seed: UInt32) -> ([Float], UInt32) {
    var s = seed
    var out = [Float](repeating: 0, count: rows * cols)
    var off = 0
    for _ in 0..<rows {
        for _ in 0..<cols {
            s = lcg(s)
            out[off] = u32ToUnit(s)
            off += 1
        }
    }
    return (out, s)
}

func rightDot(_ a: [Float], _ ao: Int, _ b: [Float], _ bo: Int, _ m: Int) -> Float {
    var acc: Float = 0
    var i = m
    while i > 0 {
        i -= 1
        acc = a[ao + i] * b[bo + i] + acc
    }
    return acc
}

func rightResidSq(_ f: [Float], _ fo: Int, _ w: [Float], _ wo: Int, _ t: Float, _ m: Int) -> Float {
    var acc: Float = 0
    var i = m
    while i > 0 {
        i -= 1
        let r = f[fo + i] - t * w[wo + i]
        acc = r * r + acc
    }
    return acc
}

func cpuAssociate(points: [Float], refs: [Float], n: Int, r: Int, m: Int) -> ([UInt32], [Float]) {
    var idx = [UInt32](repeating: 0, count: n)
    var dist = [Float](repeating: 0, count: n)
    for i in 0..<n {
        let fo = i * m
        var bestI: UInt32 = 0
        var bestD = BEST_D0
        for j in 0..<r {
            let wo = j * m
            let ww = rightDot(refs, wo, refs, wo, m)
            let d: Float
            if ww < TINY_WW {
                d = rightDot(points, fo, points, fo, m).squareRoot()
            } else {
                let t = rightDot(points, fo, refs, wo, m) / ww
                d = rightResidSq(points, fo, refs, wo, t, m).squareRoot()
            }
            if d < bestD {
                bestD = d
                bestI = UInt32(j)
            }
        }
        idx[i] = bestI
        dist[i] = bestD
    }
    return (idx, dist)
}

func cpuNicheCount(_ idx: [UInt32], r: Int) -> [UInt32] {
    var counts = [UInt32](repeating: 0, count: r)
    for v in idx {
        let j = Int(v)
        if j >= 0 && j < r { counts[j] += 1 }
    }
    return counts
}

func distClose(_ a: Float, _ b: Float) -> Bool {
    let d = abs(a - b)
    if d <= DIST_ABS { return true }
    return d <= DIST_REL * max(abs(a), abs(b), 1e-30)
}

func median(_ xs: [Double]) -> Double {
    let s = xs.sorted()
    if s.isEmpty { return 0 }
    return s[s.count / 2]
}

struct Args {
    var n = 184
    var r = 91
    var m = 3
    var seed: UInt32 = 1
    var warmup = 1
    var reps = 7
    var metal = "associate.metal"
    var json: String? = nil
    var dump = false
    var includeZeroRef = false
}

func parseArgs() -> Args {
    var a = Args()
    let argv = CommandLine.arguments
    var i = 1
    while i < argv.count {
        let k = argv[i]
        func take() -> String {
            i += 1
            return argv[i]
        }
        switch k {
        case "--n": a.n = Int(take())!
        case "--r": a.r = Int(take())!
        case "--m": a.m = Int(take())!
        case "--seed": a.seed = UInt32(take())!
        case "--warmup": a.warmup = Int(take())!
        case "--reps": a.reps = Int(take())!
        case "--metal": a.metal = take()
        case "--json": a.json = take()
        case "--dump": a.dump = true
        case "--include-zero-ref": a.includeZeroRef = true
        default:
            fputs("unknown arg \(k)\n", stderr)
            exit(2)
        }
        i += 1
    }
    return a
}

func main() {
    let args = parseArgs()
    var (points, s1) = genMatrix(rows: args.n, cols: args.m, seed: args.seed)
    var (refs, _) = genMatrix(rows: args.r, cols: args.m, seed: s1)
    if args.includeZeroRef {
        for k in 0..<args.m { refs[k] = 0 }
    }

    let tCPU0 = CFAbsoluteTimeGetCurrent()
    let (cpuIdx, cpuDist) = cpuAssociate(points: points, refs: refs, n: args.n, r: args.r, m: args.m)
    let cpuMs = (CFAbsoluteTimeGetCurrent() - tCPU0) * 1000.0
    let cpuCounts = cpuNicheCount(cpuIdx, r: args.r)

    guard let device = MTLCreateSystemDefaultDevice() else {
        fputs("no Metal device\n", stderr)
        exit(1)
    }
    let srcPath = URL(fileURLWithPath: args.metal)
    guard let src = try? String(contentsOf: srcPath, encoding: .utf8) else {
        fputs("cannot read \(args.metal)\n", stderr)
        exit(1)
    }
    let opt = MTLCompileOptions()
    opt.fastMathEnabled = false
    let library: MTLLibrary
    do {
        library = try device.makeLibrary(source: src, options: opt)
    } catch {
        fputs("Metal compile failed: \(error)\n", stderr)
        exit(1)
    }
    guard let assocFn = library.makeFunction(name: "associate"),
          let nicheFn = library.makeFunction(name: "niche_count") else {
        fputs("missing kernel function\n", stderr)
        exit(1)
    }
    let assocPSO: MTLComputePipelineState
    let nichePSO: MTLComputePipelineState
    do {
        assocPSO = try device.makeComputePipelineState(function: assocFn)
        nichePSO = try device.makeComputePipelineState(function: nicheFn)
    } catch {
        fputs("pipeline failed: \(error)\n", stderr)
        exit(1)
    }
    guard let queue = device.makeCommandQueue() else {
        fputs("no command queue\n", stderr)
        exit(1)
    }

    let pointBuf = device.makeBuffer(bytes: points, length: points.count * MemoryLayout<Float>.stride, options: .storageModeShared)!
    let refBuf = device.makeBuffer(bytes: refs, length: refs.count * MemoryLayout<Float>.stride, options: .storageModeShared)!
    let idxBuf = device.makeBuffer(length: args.n * MemoryLayout<UInt32>.stride, options: .storageModeShared)!
    let distBuf = device.makeBuffer(length: args.n * MemoryLayout<Float>.stride, options: .storageModeShared)!
    let countBuf = device.makeBuffer(length: args.r * MemoryLayout<UInt32>.stride, options: .storageModeShared)!

    var n32 = UInt32(args.n)
    var r32 = UInt32(args.r)
    var m32 = UInt32(args.m)
    let nBuf = device.makeBuffer(bytes: &n32, length: 4, options: .storageModeShared)!
    let rBuf = device.makeBuffer(bytes: &r32, length: 4, options: .storageModeShared)!
    let mBuf = device.makeBuffer(bytes: &m32, length: 4, options: .storageModeShared)!

    func dispatch(_ pso: MTLComputePipelineState, _ encoder: MTLComputeCommandEncoder, count: Int) {
        let tgWidth = min(pso.maxTotalThreadsPerThreadgroup, 256)
        let tg = MTLSize(width: tgWidth, height: 1, depth: 1)
        let grid = MTLSize(width: count, height: 1, depth: 1)
        encoder.dispatchThreads(grid, threadsPerThreadgroup: tg)
    }

    func runOnce(includeTransfer: Bool) -> (e2eMs: Double, kernelMs: Double, nicheKernelMs: Double) {
        let t0 = CFAbsoluteTimeGetCurrent()
        if includeTransfer {
            memcpy(pointBuf.contents(), points, points.count * MemoryLayout<Float>.stride)
            memcpy(refBuf.contents(), refs, refs.count * MemoryLayout<Float>.stride)
        }
        memset(countBuf.contents(), 0, args.r * MemoryLayout<UInt32>.stride)

        guard let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeComputeCommandEncoder() else {
            fputs("command buffer failed\n", stderr)
            exit(1)
        }
        enc.setComputePipelineState(assocPSO)
        enc.setBuffer(pointBuf, offset: 0, index: 0)
        enc.setBuffer(refBuf, offset: 0, index: 1)
        enc.setBuffer(idxBuf, offset: 0, index: 2)
        enc.setBuffer(distBuf, offset: 0, index: 3)
        enc.setBuffer(nBuf, offset: 0, index: 4)
        enc.setBuffer(rBuf, offset: 0, index: 5)
        enc.setBuffer(mBuf, offset: 0, index: 6)
        dispatch(assocPSO, enc, count: args.n)

        enc.setComputePipelineState(nichePSO)
        enc.setBuffer(idxBuf, offset: 0, index: 0)
        enc.setBuffer(countBuf, offset: 0, index: 1)
        enc.setBuffer(nBuf, offset: 0, index: 2)
        enc.setBuffer(rBuf, offset: 0, index: 3)
        dispatch(nichePSO, enc, count: args.n)
        enc.endEncoding()
        cmd.commit()
        cmd.waitUntilCompleted()

        // Touch outputs so the readback is part of e2e.
        let idxPtr = idxBuf.contents().bindMemory(to: UInt32.self, capacity: args.n)
        let distPtr = distBuf.contents().bindMemory(to: Float.self, capacity: args.n)
        var sink: UInt64 = 0
        sink &+= UInt64(idxPtr[0])
        sink &+= UInt64(idxPtr[args.n - 1])
        sink &+= UInt64(distPtr[0].bitPattern)
        _ = sink
        let t1 = CFAbsoluteTimeGetCurrent()

        let gpu0 = cmd.gpuStartTime
        let gpu1 = cmd.gpuEndTime
        let kernelMs = max(0, (gpu1 - gpu0) * 1000.0)
        return ((t1 - t0) * 1000.0, kernelMs, 0)
    }

    for _ in 0..<max(args.warmup, 0) {
        _ = runOnce(includeTransfer: true)
    }

    var e2e: [Double] = []
    var kern: [Double] = []
    for _ in 0..<max(args.reps, 1) {
        let r = runOnce(includeTransfer: true)
        e2e.append(r.e2eMs)
        kern.append(r.kernelMs)
    }

    let outIdx = Array(UnsafeBufferPointer(
        start: idxBuf.contents().bindMemory(to: UInt32.self, capacity: args.n),
        count: args.n
    ))
    let outDist = Array(UnsafeBufferPointer(
        start: distBuf.contents().bindMemory(to: Float.self, capacity: args.n),
        count: args.n
    ))
    let outCounts = Array(UnsafeBufferPointer(
        start: countBuf.contents().bindMemory(to: UInt32.self, capacity: args.r),
        count: args.r
    ))

    var idxMismatches = 0
    var distMismatches = 0
    var maxAbs: Float = 0
    for i in 0..<args.n {
        if outIdx[i] != cpuIdx[i] { idxMismatches += 1 }
        let d = abs(outDist[i] - cpuDist[i])
        if d > maxAbs { maxAbs = d }
        if !distClose(outDist[i], cpuDist[i]) { distMismatches += 1 }
    }
    let countsOk = outCounts == cpuCounts
    let ok = idxMismatches == 0 && distMismatches == 0 && countsOk
    let sumIdx = outIdx.reduce(0) { $0 + Int($1) }

    var result: [String: Any] = [
        "impl": "hand_msl",
        "device": device.name,
        "n": args.n,
        "r": args.r,
        "m": args.m,
        "seed": args.seed,
        "warmup": args.warmup,
        "reps": args.reps,
        "e2e_ms": e2e,
        "kernel_ms": kern,
        "e2e_median_ms": median(e2e),
        "e2e_min_ms": e2e.min() ?? 0,
        "e2e_max_ms": e2e.max() ?? 0,
        "kernel_median_ms": median(kern),
        "kernel_min_ms": kern.min() ?? 0,
        "kernel_max_ms": kern.max() ?? 0,
        "swift_cpu_ref_ms": cpuMs,
        "ok": ok,
        "idx_mismatches": idxMismatches,
        "dist_mismatches": distMismatches,
        "max_abs_dist_delta": maxAbs,
        "counts_ok": countsOk,
        "sum_idx": sumIdx,
        "counts_sum": Int(outCounts.reduce(0, +)),
        "tolerance": ["abs": DIST_ABS, "rel": DIST_REL],
    ]
    if args.dump {
        result["idx"] = outIdx.map { Int($0) }
        result["dist"] = outDist
        result["counts"] = outCounts.map { Int($0) }
    }

    let data = try! JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
    if let path = args.json {
        try! data.write(to: URL(fileURLWithPath: path))
    }
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))

    fputs("kind=hand_msl n=\(args.n) r=\(args.r) m=\(args.m) seed=\(args.seed)\n", stderr)
    fputs("ok=\(ok) idx_mismatches=\(idxMismatches) dist_mismatches=\(distMismatches) max_abs=\(maxAbs) counts_ok=\(countsOk)\n", stderr)
    fputs(String(format: "e2e_median_ms=%.4f kernel_median_ms=%.4f swift_cpu_ref_ms=%.4f sum_idx=%d\n",
                 median(e2e), median(kern), cpuMs, sumIdx), stderr)
    if args.dump {
        print("ASSIGNMENTS")
        for i in 0..<args.n {
            print("\(outIdx[i]) \(outDist[i])")
        }
        print("COUNTS")
        print(outCounts.map { String($0) }.joined(separator: " "))
    }
    exit(ok ? 0 : 1)
}

main()
