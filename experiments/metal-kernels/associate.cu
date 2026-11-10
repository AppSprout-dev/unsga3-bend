// Experimental CUDA associate + niche-count kernels.
// Same algorithm as associate.metal / src/survival.bend perp+nearest_go.
// Not a product code path. No CUDA timings are claimed in this tree:
// this file exists so the kernel can be compile-checked with nvcc when
// a toolkit is present.
#include <cuda_runtime.h>
#include <stdint.h>

__device__ inline float right_dot(const float* a, const float* b, unsigned m) {
    float acc = 0.0f;
    for (unsigned k = m; k > 0; --k) {
        unsigned i = k - 1;
        acc = a[i] * b[i] + acc;
    }
    return acc;
}

__device__ inline float right_resid_sq(const float* f, const float* w, float t, unsigned m) {
    float acc = 0.0f;
    for (unsigned k = m; k > 0; --k) {
        unsigned i = k - 1;
        float r = f[i] - t * w[i];
        acc = r * r + acc;
    }
    return acc;
}

extern "C" __global__ void associate(
    const float* points,
    const float* refs,
    unsigned* out_idx,
    float* out_dist,
    unsigned N,
    unsigned R,
    unsigned M
) {
    unsigned gid = blockIdx.x * blockDim.x + threadIdx.x;
    if (gid >= N) return;
    const float* f = points + gid * M;
    unsigned best_i = 0;
    float best_d = 1000000000.0f;
    for (unsigned j = 0; j < R; ++j) {
        const float* w = refs + j * M;
        float ww = right_dot(w, w, M);
        float d;
        if (ww < 1.0e-16f) {
            d = sqrtf(right_dot(f, f, M));
        } else {
            float t = right_dot(f, w, M) / ww;
            d = sqrtf(right_resid_sq(f, w, t, M));
        }
        if (d < best_d) {
            best_d = d;
            best_i = j;
        }
    }
    out_idx[gid] = best_i;
    out_dist[gid] = best_d;
}

extern "C" __global__ void niche_count(
    const unsigned* idx,
    unsigned* counts,
    unsigned N,
    unsigned R
) {
    unsigned gid = blockIdx.x * blockDim.x + threadIdx.x;
    if (gid >= N) return;
    unsigned r = idx[gid];
    if (r < R) atomicAdd(&counts[r], 1u);
}

// Host stub so `nvcc -c associate.cu` has a translation unit that links
// the kernels (no device runtime is invoked).
void associate_launch_stub() {
    (void)associate;
    (void)niche_count;
}
