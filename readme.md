# Bitcoin Electrum Seed Recovery (Last Missing Words)


## Technical Analysis of the Version Pre‑Filter (HMAC)

<img width="817" height="305" alt="ascii-art-text-removebg-preview" src="https://github.com/user-attachments/assets/b9808a4b-e950-44e9-bd22-4e74563598c1" />

**Attention** This pipeline hit ~4 quadrillion seed‑vs‑wallet checks in one day on a 4070 Laptop GPU. Yes, really. 🚀

🧬 **Bruno da Silva** — Security Researcher | Blockchain & Cryptography  
📧 [bsbruno@proton.me](mailto:bsbruno@proton.me)  
📱 [+55 11 99740‑2197](https://wa.me/5511997402197)  
___  
##### GitHub: [ipsbruno](https://github.com/ipsbruno) | [ipsbrunoreserva](https://github.com/ipsbrunoreserva) | [ipsbruno3](https://github.com/ipsbruno3)  
##### Pastebin: [ipsBruno](https://pastebin.com/u/ipsBruno) | [Drakins](https://pastebin.com/u/Drakins)

---



<img width="450" height="250" alt="image" src="https://github.com/user-attachments/assets/9ef356c6-35f2-41e3-b576-dd43b4552f24" />

-- **Use:** For **legitimate self‑recovery** only.

-- **Open** Source

--  **You can audit** every code
---

## 1) Context and Structural Differences

- **BIP‑39 (12 words)** encodes **132 bits** in total: 11 bits per word × 12 words.  
- **Effective entropy**: **128 bits**; the remaining **4 bits** are a **checksum** embedded in the last word.  
- Consequently, only **1 in 16** random 12‑word sequences pass the BIP‑39 checksum.  
- Seed derivation (BIP‑39 mnemonic to seed): **PBKDF2‑HMAC‑SHA512 (2048 iterations)**.

### Electrum v2 (12 or 24 words)

- Embeds an explicit **seed version/type**, verified via **HMAC‑SHA512** with a fixed label (e.g., `"Seed version"`).  
- The HMAC digest is checked against known version prefixes (Standard, Segwit, 2FA).  
- Typical prefix acceptance probabilities:
  - **Standard:** ~1/256 (k = 8 accepted bits)
  - **Segwit/2FA:** ~1/4096 (k = 12 accepted bits)
- Electrum still employs **PBKDF2‑HMAC‑SHA512 (2048)** for internal seed derivation after the version check.

**Key implication:** Electrum allows a **cheap, deterministic HMAC pre‑filter** (1 HMAC per candidate) that discards most invalid mnemonics **before** PBKDF2. BIP‑39 has to run PBKDF2 on every checksum‑valid candidate. This is the lever that makes large searches tractable at scale.

---

## 2) BIP‑39 Keyspace Calculation

Valid BIP‑39 12‑word combinations with `u` unknown words:

$
N_{\text{BIP39}}(u) = 2048^{(u-1)} \times 128 = 2^{11u - 4}
$

Example (`u = 5`):

$
N_{\text{BIP39}}(5) = 2048^4 \times 128 = 2^{51} \approx 2.25 \times 10^{15}
$

✅ **Final Expression:**

$
\boxed{N_{\text{BIP39}}(5) \approx 2.25 \text{ quadrillion}}
$

---

## 3) Electrum Keyspace Calculation (Segwit Example)

Electrum’s acceptance does **not** follow the BIP‑39 checksum. Instead, it filters candidates via a **version HMAC prefix** with probability:

$
p_k = 2^{-k}
$

Expected PBKDF2 candidates:

$
N_{\text{Electrum}}^{(\text{PBKDF2})}(u,k) = 2048^u \times 2^{-k} = 2^{11u - k}
$

Example (`u = 5`):

- \(k = 12 \Rightarrow 2^{55-12} = 2^{43} \approx 8.79 \times 10^{12}\)  
- \(k = 8 \Rightarrow 2^{55-8} = 2^{47} \approx 1.40 \times 10^{14}\)

✅ **Final Expression:**

$
\boxed{N_{\text{Electrum}}^{(\text{PBKDF2})}(5,12) \approx 8.79 \text{ trillion}}
$

> Note: “0.5 factor” rules of thumb for segwit/2FA are inaccurate here; the true filter is \(2^{-k}\).

---

## 4) Cost Model — PBKDF2 vs HMAC Pre‑Filter

Let:

- \(C_H =\) cost of one **HMAC‑SHA512**  
- \(C_P =\) cost of one **PBKDF2‑HMAC‑SHA512 (2048 iter.)**

A coarse but useful ratio:

$
\rho = \frac{C_P}{C_H} \approx 2048
$

### 4.1 PBKDF2 Calls Avoided

Theoretical reduction in PBKDF2 workload:

$
\frac{N_{\text{BIP39}}(u)}{N_{\text{Electrum}}^{(\text{PBKDF2})}(u,k)} = 2^{k-4}
$

- \(k = 12 \Rightarrow\) **256× fewer PBKDF2 calls**  
- \(k = 8 \Rightarrow\) **16× fewer PBKDF2 calls**

### 4.2 Total Cost Ratio (End‑to‑End Speedup)

$
\text{Speedup}(k) = \frac{128}{1 + 2^{11-k}}
$

- \(k = 12 \Rightarrow \approx 85.3\times\)  
- \(k = 8 \Rightarrow \approx 14.2\times\)

---

:warning: Even with one HMAC per candidate, the PBKDF2 reduction dominates total cost. Net gains between **~10× and ~100×** are fully realistic, depending on seed type and implementation.

---

## 5) Why Electrum’s Pre‑Filter Enables Recovery

1. **Two‑phase design**  
   A: low‑cost HMAC prefix check.  
   B: expensive PBKDF2 only for survivors.

2. **Massive PBKDF2 drop**  
   From all combinations down to \(2^{11u-k}\).

3. **GPU‑friendly**  
   Independent HMAC checks scale linearly on OpenCL.

4. **Deterministic versioning**  
   Accepts only candidates that match the desired Electrum seed type and derivation behavior.

---

## 6) Speedtests ✅

#### NVIDIA 4070 Laptop
- **15,347,929 seeds/s** measured in the OpenCL kernel path 😲  
- **52,111,345 hash‑table lookups/s** on the host index

> Figures depend on clocking, thermal headroom, LWS/GWS, and input distribution.

---

## 7) Assumptions and Limitations

- Applies to **Electrum v2** (12/24 words). Prefix length \(k\) is implementation‑specific.  
- No additional passphrase/extension unless explicitly configured.  
- \(\rho\) is a back‑of‑the‑envelope ratio; real devices deviate.  
- Keyspace math assumes uniform distribution of unknown words.

---

## 8) References

- BIP‑39: mnemonic encoding, entropy, checksum.  
- Electrum: seed versioning, HMAC prefix checks.  
- PBKDF2‑HMAC‑SHA512: cryptographic cost profile.  
- OpenCL: GPU parallelization patterns for crypto workloads.

---

## 9) Conclusions

- Electrum’s HMAC pre‑filter doesn’t shrink entropy; it **shifts** expensive work to a drastically smaller, verifiable subset.  
- For segwit seeds (k ≈ 12), PBKDF2 workload typically drops by **~256×**.  
- Considering overheads, **~85×** total speedup is feasible on modern GPUs.  
- The HMAC filter is the key for practical large‑scale Electrum seed recovery.

---

**Ethical Notice:**  
This material exists to support **legitimate recovery** of wallets **owned by the operator**. Unauthorized access to third‑party wallets is **illegal and unethical**.

---



## Hash‑Table Index by `tag64` + Returning Seed Indices  
### GPU ↔ HOST (Python + OpenCL) Pipeline: Technical Documentation

---

## Overview

0. **Environment**: Put the target pattern in `.env`:

   ```
   SEED=camel cable car jockey party skip sky ? ? ? ? ?
   ```

   The current pipeline targets mnemonics with the **last words missing**. Three missing words are often solvable within a few hours at scale, thanks to the pre‑filter plus hash‑table matching.

1. **Host (Python)**  
   - Reads a GZIP of Bech32 addresses.  
   - For each v0 P2WPKH address (20‑byte program), computes **`tag64`** = the **first 8 bytes** of HASH160 in **little‑endian**.  
   - Inserts into a **hash‑table** mapping **`tag64 → list of candidates`**.

2. **Kernel (OpenCL)**  
   - Generates a 12‑word candidate mnemonic from `(memHigh, memLow)` with a wraparound low part.  
   - Checks **Electrum seed version** (segwit/standard) using an HMAC prefix.  
   - Derives `m/0'/0/0`, compresses the public key, computes HASH160(pub), extracts the same **`tag64`**.  
   - On hit, writes to a ring buffer:
     - `tag64` (8 bytes)  
     - **`widx[12]`**: the **12 word indices** (`ushort` each) for the exact mnemonic tested (24 bytes).  
     - Total per hit: **32 bytes**.

3. **Host (Python)**  
   - Reads device hits.  
   - For each `tag64`, performs **O(1)** lookup in the hash‑table (int key → vector of candidates).  
   - Reconstructs the exact mnemonic from `widx[12]` and outputs candidates for final checks or wallet probing.

---

## Hash‑Table on the Host (Python)

### Essential helpers

```python
from bech32 import bech32_decode, convertbits

def decode_addr(addr: str):
    """Bech32 decoder. Returns (hrp, ver, prog)."""
    out = bech32_decode(addr)
    if not out or out[0] is None:
        raise ValueError("Invalid Bech32")
    hrp, data = out[0], out[1]
    if not data:
        raise ValueError("Empty payload")
    ver = data[0]
    prog = bytes(convertbits(data[1:], 5, 8, False) or [])
    if not (0 <= ver <= 16):
        raise ValueError("Invalid witness version")
    if not (2 <= len(prog) <= 40):
        raise ValueError("Invalid witness program length")
    if ver == 0 and len(prog) not in (20, 32):
        raise ValueError("v0 must be 20 or 32 bytes")
    return hrp, ver, prog

def tag64_from_h160_prefix8(h160: bytes) -> int:
    """Little‑endian integer from the first 8 bytes of HASH160."""
    return int.from_bytes(h160[:8], "little")
```

### Building the index

```python
import gzip
from collections import defaultdict

def build_tag64_index(base_gz: str, hrps=("bc", "tb")):
    """
    Indexes v0 P2WPKH (20‑byte program) addresses only.
    Returns:
      - index: dict[tag64] -> list[(ver, prog, addr)]
      - addr_set: set of accepted addresses
      - stats: ingestion metrics
    """
    index = defaultdict(list)
    addr_set = set()
    total = valid = 0

    with gzip.open(base_gz, "rt", encoding="utf-8", errors="ignore") as f:
        for line in f:
            s = line.strip()
            if not s:
                continue
            total += 1

            addr = s.split()[0]
            if not (addr.startswith("bc1") or addr.startswith("tb1")):
                continue

            try:
                hrp, ver, prog = decode_addr(addr)
            except Exception:
                continue

            if hrp not in hrps:
                continue
            if ver != 0 or len(prog) != 20:
                continue

            t64 = tag64_from_h160_prefix8(prog)
            index[t64].append((ver, prog, addr))
            addr_set.add(addr)
            valid += 1

    stats = {"lines_read": total, "v0_count": valid, "unique_tags": len(index)}
    return index, addr_set, stats
```

**What each structure means**

- `index`: our **hash‑table** keyed by a 64‑bit integer (`tag64`), mapping to a list of candidates sharing the same HASH160 prefix.  
- `addr_set`: optional set of all accepted addresses (for metrics).  
- `stats`: ingestion counters for quick sanity checks.

**Why `tag64` works well**  
It’s a **cheap pre‑filter** with very low empirical collision rate for v0 P2WPKH in large datasets. By grouping candidates into tiny buckets, we cut down host‑side work before any wallet probing.

---

## Device → Host Hit Format

### Compact `hit_t` struct

```c
typedef struct {
    ulong  tag64;     // 8 bytes: LE(HASH160[0..7])
    ushort widx[12];  // 24 bytes: 12 word indices (0..2047)
} hit_t;
// sizeof(hit_t) = 32 bytes
```

On the host:

```python
import numpy as np

HIT_DTYPE = np.dtype([
    ('tag64','<u8'),
    ('widx', '<u2', (12,)),
])  # 32 bytes per hit
```

**Rationale**  
- `tag64` is enough for hash‑table lookup.  
- `widx[12]` encodes the kernel’s exact mnemonic. No recomputation, no checksum guesswork; just map wordlist indices to strings.

---

## Kernel `verify`: essential flow

Signature:

```c
__kernel void verify(__global const ulong *first,
                     __global const ulong *H,
                     __global const ulong *L,
                     __global hit_t *out_hits,
                     OUTCNT_ARG out_count,
                     const uint max_hits);
```

1) **Global thread ID**

```c
const uint gid = get_global_id(0);
```

2) **Candidate space (wrap in low 64 bits)**

```c
const ulong memHigh  = H[0];
const ulong firstMem = L[0];
const ulong memLow   = firstMem + (ulong)gid + first[0];
```

3) **Mnemonic assembly**

```c
uint  seedNum[16] = {0};      // stores up to 12 indices
uchar mnemonicString[128] = {0};
uint  offset = 0;

prepareSeedNumber(seedNum, memHigh, memLow);
prepareSeedString(seedNum, mnemonicString, offset);

if (offset == 0) return;
const size_t mlen = (size_t)offset - 1;
```

4) **Electrum version check + BIP32 derivation**

```c
ulong G[8] = {0};
hmac_sha512_seed_c99_ex(mnemonicString, mlen, G);
if (!isElectrumSegwit(G)) return;

// PBKDF2 + “Bitcoin seed” HMAC + BIP32 path m/0'/0/0
// -> public key -> compressed -> HASH160
```

5) **Device‑side tag**

```c
const ulong t64 = b32sw_tag64_from_xy_le(X, Y); // LE(HASH160[0..7])
```

6) **Ring buffer write with atomics**

```c
const uint slot = (uint)OUTCNT_FETCH();
if (slot >= max_hits) return;

out_hits[slot].tag64 = t64;
for (int j = 0; j < 12; ++j)
    out_hits[slot].widx[j] = (ushort)seedNum[j];
```

---

## Reading hits on the host

```python
# device buffers
hits_buf      = cl.Buffer(ctx, cl.mem_flags.READ_WRITE, size=HIT_DTYPE.itemsize * MAX_HITS)
out_count_buf = cl.Buffer(ctx, cl.mem_flags.READ_WRITE, size=4)
cl.enqueue_fill_buffer(queue, out_count_buf, np.uint32(0), 0, 4)

# kernel args
k.set_args(first_buf, H_buf, L_buf, hits_buf, out_count_buf, np.uint32(MAX_HITS))

# launch
ev = cl.enqueue_nd_range_kernel(queue, k, (N,), (LWS,))
ev.wait()

# number of hits
count_host = np.empty(1, dtype=np.uint32)
cl.enqueue_copy(queue, count_host, out_count_buf).wait()
n = int(min(count_host[0], MAX_HITS))

# read hits
hits = np.empty(n, dtype=HIT_DTYPE)
if n:
    cl.enqueue_copy(queue, hits, hits_buf).wait()
```

---

## Reconstructing words and matching the index

```python
from mnemonic import Mnemonic
mnemo = Mnemonic("english")

def words_from_indices(indices12: np.ndarray) -> str:
    return " ".join(mnemo.wordlist[int(x)] for x in indices12.tolist())

tags_ok = 0
candidates = 0
matched = []

for rec in hits:                 # each rec has 'tag64' and 'widx'
    t64 = int(rec['tag64'])
    bucket = index.get(t64, [])  # list of (ver, prog, addr)
    if not bucket:
        continue

    tags_ok += 1
    candidates += len(bucket)

    mn = words_from_indices(rec['widx'])  # exact device mnemonic

    for (_ver, _prog, addr) in bucket:
        matched.append({"addr": addr, "mnemo": mn})
```

---

## Endianness sanity

- **`tag64`**: always **little‑endian** on both device and host (first 8 bytes of HASH160).  
- **`widx[12]`**: 12 word indices in range `[0, 2047]`. Rebuilding the mnemonic is a direct index→string map using the standard BIP‑39 English wordlist.  
- **Electrum version check**: independent from BIP‑39 checksum; candidates are validated via HMAC seed version semantics.

---

## Sizes and costs

- `hit_t` is **32 bytes**.  
- 250k hits ≈ **8 MB** per batch — trivial for PCIe and host processing.  
- Hash‑table:
  - Key: 64‑bit `tag64`.  
  - Value: list of `(ver, prog, addr)` targets for that prefix.  
  - Expected **O(1)** lookup.

---

## Quick checklist

- [x] Binary compatibility: `hit_t` ⇄ `HIT_DTYPE` (32 bytes).  
- [x] Identical `tag64` computation on device and host.  
- [x] Rebuild mnemonic purely from `widx[12]`.  
- [x] Ring buffer guarded by atomic counter and `max_hits`.  
- [x] Bech32 restricted to `hrp ∈ {bc, tb}`, `ver = 0`, `len(prog) = 20`.  
- [x] OpenCL kernel optimized for throughput while host index resolves buckets in real time.

---

## Why the design works

- `tag64` collapses the search space to tiny buckets at negligible cost.  
- Returning `widx[12]` eliminates ambiguity (checksum, endianness, formatting): host reconstruction is lossless.  
- Host never re‑derives ECC for verification; it just maps indices → words and proceeds with wallet tests if needed.

---

## PBKDF2‑HMAC‑SHA512 (2048) — Implemented Optimizations

**Parameters:** `PBKDF2‑HMAC‑SHA512(password=normalized_mnemonic, salt="electrum"+passphrase, iter=2048, dkLen=64)`  
With `dkLen=64`, there is **one block** (`INT(1)=0x00000001`), so we compute **U1..U2048** and XOR them into **T**.

**Baseline cost:** An unoptimized HMAC often performs **4 SHA‑512 compressions** per iteration (2 inner, 2 outer), leading to **8192** total compressions per candidate.

**Optimizations applied:**

1. **Hoisted `K^ipad` / `K^opad` blocks** in `__private` regs (no rebuild per iter).  
2. **Pre‑packed SHA‑512 blocks** with fixed padding and bit‑length:  
   - inner for `U1`: 1120 bits; inner for `Uj (j≥2)`: 1536 bits; outer always 1536 bits.  
   - only the **8 variable words** are rewritten each iteration.  
3. **Midstate caching** for `K^ipad` and `K^opad`: each HMAC becomes **2 compressions** (inner+outer), not 4.  
4. **XOR accumulator** `T` kept in eight 64‑bit regs (`ulong[8]`) with unrolled looaps.  
5. **Inline + `#pragma unroll`** in hot loops; no `printf`, no global temps.  a
6. **Address spaces**: constants in `__constant`, work arrays in `__private`, avoiding casts.  
7. **Single‑block PBKDF2** logic (since `dkLen=64`), simplifying control flow.

**Impact:** The PBKDF2 core approaches **~2×** faster per candidate; system‑wide speedups further multiply with the Electrum HMAC filter.

---

]

# secp256k1 EC Engine: Algorithms and Optimizations

This document explains, in practical and implementation-level detail, the elliptic-curve engine you shared, focused on **secp256k1** arithmetic and the scalar multiplication core (`point_mul_xy`). It also covers how the code maps cleanly onto GPU execution (OpenCL), why specific tricks are used, and what the performance implications are.

---

## Curve, Field, and Representation

- **Curve:** `y² = x³ + 7` over the prime field **p = 2²⁵⁶ − 2³² − 977** (secp256k1).  
  ```c
  #define SECP256K1_B 7
  #define SECP256K1_P0 0xfffffc2f
  #define SECP256K1_P1 0xfffffffe
  #define SECP256K1_P2 0xffffffff
  #define SECP256K1_P3 0xffffffff
  #define SECP256K1_P4 0xffffffff
  #define SECP256K1_P5 0xffffffff
  #define SECP256K1_P6 0xffffffff
  #define SECP256K1_P7 0xffffffff
  ```

- **Field element / Scalar representation:** **8×32‑bit little‑endian** limbs (arrays of `uint[8]`).  
  This aligns with GPU-friendly 32‑bit ALUs, enabling short carry chains and unrolling.

- **Special constant:** `0x3D1 = 977`, which is the small correction term in `p = 2²⁵⁶ − 2³² − 977`.  
  That constant is reduction routine for fast modulo operations.

---

## Field Arithmetic (mod p)

### Addition and Subtraction (with conditional reduction)
The code implements word-wise add/sub with manual carry/borrow, followed by a **single** conditional subtraction of `p` on overflow or on result ≥ p:

```c
uint add(uint *r, const uint *a, const uint *b);
uint sub(uint *r, const uint *a, const uint *b);
inline void add_mod(uint *r, const uint *a, const uint *b) { ... }
inline void sub_mod(uint *r, const uint *a, const uint *b) { ... }
```

Why it matters:
- 32‑bit limbs let the compiler interleave instructions (ILP).  
- A single conditional subtraction keeps the path short and branch-light.

### Multiplication with Pseudo-Mersenne Reduction

The product of two 256‑bit numbers is a 512‑bit value `t[0..15]`. Reduction mod `p = 2²⁵⁶ − 2³² − 977` uses the identity:

```
x · 2²⁵⁶ ≡ x · (2³² + 977) mod p
```

So high limbs `t[8..15]` are folded back into the low half by:
1. **Shift by 32 bits** (`<< 32`) and
2. **Add 977×(high limbs)** into low words.

That is exactly what the code does with multiple accumulations of `0x3D1` and the 32‑bit shift:

```c
void mul_mod(uint *r, const uint *a, const uint *b) {
    uint t[16] = {0};
    // 1) schoolbook multiply -> t[0..15]
    // 2) fold high half using p = 2^256 - 2^32 - 977 (0x3D1)
    //    ... add (high << 32) and 977*high into the low half
    // 3) final conditional subtraction(s) to ensure r < p
}
```

Effect:
- No division; reduction is just a few adds, shifts, and small constant multiplies.  
- Excellent fit for GPU integer units.

### Modular Inverse: Binary Extended GCD (with “halve mod p” trick)

The code uses a **binary extended GCD** style inversion (`inv_mod`), with repeated halving and conditional additions of `p` to keep numbers even before right shifts:

```c
void inv_mod(uint *a) {
    // t0 = a, t1 = p, t2 = 1, t3 = 0
    // while (t0 != t1):
    //   if even(t0): t0 >>= 1; t2 = (t2 even ? t2>>1 : (t2+p)>>1);
    //   else if even(t1): t1 >>= 1; t3 = (t3 even ? t3>>1 : (t3+p)>>1);
    //   else { subtract larger - smaller; then halve smaller side (mod p) }
    // finally: a = t2
}
```

Why it matters:
- Avoids general 256‑bit division.  
- Right shifts with conditional `+p` are fast and simple per-limb.  
- One inversion per scalar multiplication (at the end) is much cheaper than doing inversions inside the ladder.

---

## Point Representation and Group Operations

### Coordinates

- **Jacobian coordinates** for the running point `(X:Y:Z)`.  
- **Affine** for precomputed points (constant table), so additions are **mixed** (Jacobian + affine, `z2 = 1`).

### Doubling (`point_double`)

Implements standard doubling formulas with a “division-by-two mod p” halving trick:
- When halving an odd element, add `p` first, then shift right by one limb chain.  
- Minimal branches, predictable memory access.

```c
void point_double(uint *x, uint *y, uint *z) {
    // Computes (X3,Y3,Z3) = 2*(X1,Y1,Z1) in Jacobian
    // Uses: X^2, Y^2, (Y*Z), and halving tricks mod p
}
```

### Mixed Addition (`point_add` with `z2=1`)

Adds an affine precomputed point `(x2, y2, 1)` to a Jacobian point `(x1, y1, z1)`:

```c
void point_add(uint *x1, uint *y1, uint *z1, __constant uint *x2, __constant uint *y2) {
    // t6 = z1^2; t7 = z1^3; U2 = x2*t6; S2 = y2*t7;
    // H = U2 - X1; R = S2 - Y1;
    // Z3 = z1*H;
    // X3 = R^2 - H^2 - 2*X1*H^2;
    // Y3 = R*(X1*H^2 - X3) - Y1*H^3;
}
```

Why mixed addition:
- Saves one multiplication (no need to scale z2).  
- Less latency and fewer temporaries than full Jacobian+Jacobian addition.

### Final Normalization (Jacobian → Affine)

A **single modular inverse** is performed at the end:

```c
inv_mod(z1);
uint z2[8];  mul_mod(z2, z1, z1);
mul_mod(x1, x1, z2);
mul_mod(z1, z2, z1);
mul_mod(y1, y1, z1);
// (x1, y1) are now affine
```

---

## Scalar Multiplication: Windowed NAF (wNAF, width = 4)

### wNAF Encoding

The code converts the scalar `k` to **windowed Non-Adjacent Form** with width 4 (nibbles). Each digit is in `{-8, …, -1, 0, +1, …, +7}` and is packed into 4‑bit slots inside `naf[]`:

```c
int convert_to_window_naf(uint *naf, const uint *k) {
    // Scans k bit-by-bit (LSB → MSB),
    // picks odd digits in [-8..+7], adjusts k, and shifts.
    // Stores 4-bit digits in naf[], returns index of top non-zero digit.
}
```

Why wNAF:
- Non-zero digits are sparse by design, minimizing the number of additions.  
- Using width 4 balances table size vs. number of additions well for GPUs.

### Precomputed Table in Constant Memory

A small table `secpk256PreComputed[96]` holds affine coordinates for odd multiples used by the wNAF window, laid out as 32‑bit little‑endian limbs:

```c
__constant uint secpk256PreComputed[96] = {
  // 96 words (32-bit) => 12 limbs per coordinate pair *
  // Packed as [X (8 words), Y (8 words)] for a sequence of odd multiples.
};
```

Lookup is derived directly from the 4‑bit wNAF digit:
```c
const uint multiplier = (naf[pos >> 3] >> ((pos & 7) << 2)) & 0x0f;
const uint odd = multiplier & 1;
const uint x_pos = ((multiplier - 1 + odd) >> 1) * 24;
const uint y_pos = odd ? (x_pos + 8) : (x_pos + 16);

// Pull x,y from __constant for mixed addition.
point_add(x1,y1,z1, secpk256PreComputed + x_pos, secpk256PreComputed + y_pos);
```

Effect:
- **Constant-time style** lookups (index arithmetic) avoid branchy decision trees.  
- Constant memory is cached and broadcast-friendly on GPUs.

### Ladder

`point_mul_xy` performs:
1. wNAF conversion of `k`.  
2. Initializes `(X,Y,Z)` with the highest non-zero wNAF digit from the table.  
3. Scans down the digits: one **point double** per step, and **conditionally** a mixed addition when the nibble is non-zero.  
4. One inversion at the end to return affine `(X,Y)`.

---

## Endianness, Parity, and PubKey Compression

- Internally, integers use **LE limbs**.  
- The compressed pubkey prefix **0x02 / 0x03** is determined by the **LSB of Y**: `prefix = (Y[0] & 1) ? 0x03 : 0x02` (no extra byte swaps).  
- Serialization of X to bytes uses a single **LE → BE** conversion at output time, which is the only place where BE is needed.

---

## Performance Characteristics

- **Arithmetic:** optimized for 32‑bit limbs; short carry chains; specialized reduction mod `p`.  
- **Inversion:** binary GCD variant with halving mod `p` trick.  
- **Scalar multiplication:** wNAF(4) + mixed addition + one inversion → excellent latency/throughput on GPU.  
- **Memory:** precomputed affine points in `__constant`, all hot-path temporaries in `__private` (registers).  
- **Branching:** minimized and predictable; lookup arithmetic instead of nested `if` ladders.

---

## Security Notes

- wNAF digits are derived from secret `k`. This implementation uses table lookups indexed by nibble values; on GPUs, power/timing side-channels are less explored but still a consideration on shared hardware.  
- If side-channels matter, ensure *constant-time table access* (e.g., read all rows and mask-select, or rely on GPU SIMD uniformity where applicable).  
- Input validation and reduction of scalars to the group order `n` should happen upstream.

---

## Integration Context

This EC module is used as part of a BIP32/Electrum derivation pipeline:
- Scalars (`k`) arrive in **4×64‑bit BE** from HMAC outputs.  
- A small adapter converts to **8×32‑bit LE** and feeds `point_mul_xy`.  
- The resulting `(X,Y)` is compressed and then hashed (SHA‑256 → RIPEMD‑160) to form Bech32 P2WPKH witnesses.

Because the data layout and conversions are minimized (and happen only at boundaries), the ECC cost is a small fraction of the total runtime compared to PBKDF2‑HMAC‑SHA512, which dominates the pipeline.

---

## TL;DR

- **Field arithmetic**: 8×32 LE, pseudo‑Mersenne reduction for `p = 2²⁵⁶ − 2³² − 977`.  
- **Inversion**: binary extended GCD with halving trick.  
- **Scalar mul**: **wNAF(4)**, constant-memory precomputed odd multiples, mixed addition, one inversion at the end.  
- **Compression**: prefix from `Y[0] & 1`, serialize X to BE once.  
- **Result**: a compact, GPU-friendly secp256k1 engine with low branching and high throughput.



--
-

-



**End of document.**


