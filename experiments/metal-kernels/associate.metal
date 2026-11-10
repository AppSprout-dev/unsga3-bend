// Experimental associate + niche-count kernels.
// Matches unsga3-bend src/survival.bend perp / nearest_go / resid_sq:
//   ww = ||w||^2                     (right-fold dot)
//   if ww < 1e-16: d = ||f||         (right-fold)
//   else t = dot(f,w)/ww; d = sqrt(sum_k (f_k - t*w_k)^2)  (right-fold)
//   argmin on strict < (ties keep the lower index)
// Not a product code path.
#include <metal_stdlib>
using namespace metal;

inline float right_dot(const device float* a, const device float* b, uint m) {
    float acc = 0.0f;
    // Right-fold: a0*b0 + (a1*b1 + (... + 0))
    for (uint k = m; k > 0; --k) {
        uint i = k - 1;
        acc = a[i] * b[i] + acc;
    }
    return acc;
}

inline float right_resid_sq(const device float* f, const device float* w, float t, uint m) {
    float acc = 0.0f;
    for (uint k = m; k > 0; --k) {
        uint i = k - 1;
        float r = f[i] - t * w[i];
        acc = r * r + acc;
    }
    return acc;
}

kernel void associate(
    device const float* points [[buffer(0)]],
    device const float* refs   [[buffer(1)]],
    device uint*        out_idx [[buffer(2)]],
    device float*       out_dist [[buffer(3)]],
    constant uint&      N [[buffer(4)]],
    constant uint&      R [[buffer(5)]],
    constant uint&      M [[buffer(6)]],
    uint gid [[thread_position_in_grid]]
) {
    if (gid >= N) return;
    const device float* f = points + gid * M;
    uint best_i = 0;
    float best_d = 1000000000.0f;
    for (uint j = 0; j < R; ++j) {
        const device float* w = refs + j * M;
        float ww = right_dot(w, w, M);
        float d;
        if (ww < 1.0e-16f) {
            d = sqrt(right_dot(f, f, M));
        } else {
            float t = right_dot(f, w, M) / ww;
            d = sqrt(right_resid_sq(f, w, t, M));
        }
        if (d < best_d) {
            best_d = d;
            best_i = j;
        }
    }
    out_idx[gid] = best_i;
    out_dist[gid] = best_d;
}

kernel void niche_count(
    device const uint*        idx    [[buffer(0)]],
    device atomic_uint*       counts [[buffer(1)]],
    constant uint&            N      [[buffer(2)]],
    constant uint&            R      [[buffer(3)]],
    uint gid [[thread_position_in_grid]]
) {
    if (gid >= N) return;
    uint r = idx[gid];
    if (r < R) {
        atomic_fetch_add_explicit(&counts[r], 1u, memory_order_relaxed);
    }
}
