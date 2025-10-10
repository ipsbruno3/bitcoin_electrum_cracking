# 🚀 Bitcoin Electrum Seed Recovery (12 words | Last Missing Words) — Technical Analysis of the Version Pre-Filter (HMAC)

<img width="817" height="305" alt="ascii-art-text-removebg-preview" src="https://github.com/user-attachments/assets/b9808a4b-e950-44e9-bd22-4e74563598c1" />

🧬 **Bruno da Silva** — Security Researcher | Blockchain & Cryptography
📧 [bsbruno@proton.me](mailto:bsbruno@proton.me)
📱 [+55 11 99740-2197](https://wa.me/5511997402197)
___
GitHub: [ipsbruno](https://github.com/ipsbruno) | [ipsbrunoreserva](https://github.com/ipsbrunoreserva) | [ipsbruno3](https://github.com/ipsbruno3) 
---
Pastebin: [ipsBruno](https://pastebin.com/u/ipsBruno) | [Drakins](https://pastebin.com/u/Drakins)

---

> **Scope:** Technical explanation of how **Electrum v2** seeds implement an **HMAC-based pre-filter**, reducing brute-force complexity when recovering missing words from a 12-word mnemonic.
> **Use:** For **legitimate self-recovery** only.

---

## 1) Context and Structural Differences

* A 12-word mnemonic encodes **132 bits** (11 bits per word).
* Effective entropy: **128 bits** + **4-bit checksum** embedded in the last word.
* Therefore, only **1 in 16** random sequences pass the BIP-39 checksum.
* Seed derivation: **PBKDF2-HMAC-SHA512** (2048 iterations).

### Electrum v2 (12 or 24 words)

* Includes an explicit **seed version/type**, verified via **HMAC-SHA512** with a known label (`Seed version`).
* HMAC output is checked against known version prefixes (Standard, Segwit, 2FA).
* Typical prefix probabilities:

  * **Standard:** ~1/256 ($k = 8$)
  * **Segwit/2FA:** ~1/4096 ($k = 12$)
* Uses **PBKDF2-HMAC-SHA512** (2048 iterations) for internal seed derivation.

**Key implication:** Electrum enables a cheap, deterministic **HMAC pre-filter** (1 HMAC per candidate) that discards most invalid mnemonics **before** PBKDF2, unlike BIP-39, which must run PBKDF2 on all checksum-valid seeds.

---

## 2) BIP-39 Keyspace Calculation

BIP-39 valid combinations for `u` unknown words:

$$
N_{BIP39}(u) = 2048^{(u-1)} \times 128 = 2^{11u-4}
$$

Example (`u = 5`):

$$
N_{BIP39}(5) = 2048^4 \times 128 = 2^{51} = 2.25 \times 10^{15}
$$

✅ **Final Expression:**

$$
\boxed{N_{BIP39}(5) = 2.25\text{ quadrillion}}
$$

---

## 3) Electrum Keyspace Calculation (Segwit Example)

Electrum validation does **not** depend on the BIP-39 checksum. Instead, it filters candidates via an **HMAC version prefix check** with probability:

$$
p_k = 2^{-k}
$$

The expected number of PBKDF2 candidates:

$$
N_{Electrum}^{(PBKDF2)}(u, k) = 2048^u \times 2^{-k} = 2^{11u - k}
$$

Example (`u = 5`):

* $k = 12$ → $2^{55-12} = 2^{43} = 8.79 \times 10^{12}$
* $k = 8$  → $2^{55-8} = 2^{47} = 1.40 \times 10^{14}$

✅ **Final Expression:**

$$
\boxed{N_{Electrum}^{(PBKDF2)}(5,12) = 8.79 \times 10^{12}}
$$

> Note: The often-cited factor of 0.5 is an oversimplification (Segwit/2FA Addresses); actual filtering probability is $2^{-k}$, not fixed.

---

## 4) Cost Model — PBKDF2 vs HMAC Pre-Filter

Define:

* $C_H$ = cost of one **HMAC-SHA512**
* $C_P$ = cost of one **PBKDF2-HMAC-SHA512 (2048 iterations)**

Approximate cost ratio:

$$
\rho = \frac{C_P}{C_H} \approx 2048
$$

### 4.1 PBKDF2 Calls Avoided

Theoretical reduction:

$$
\frac{N_{BIP39}(u)}{N_{Electrum}^{(PBKDF2)}(u,k)} = 2^{k-4}
$$

* $k = 12$ → **256× fewer PBKDF2 calls**
* $k = 8$ → **16× fewer PBKDF2 calls**

### 4.2 Total Cost Ratio (Speedup)

$$
\text{Speedup}(k) = \frac{128}{1 + 2^{11-k}}
$$

* $k = 12$ → $\approx 85.3\times$
* $k = 8$  → $\approx 14.2\times$

> Even though each candidate needs one HMAC, the massive PBKDF2 reduction yields a net 10–100× overall improvement, depending on seed type.

---

## 5) Why Electrum’s Pre-Filter Enables Recovery

1. **Two-phase design:**

   * Stage A: cheap HMAC check for version prefix.
   * Stage B: expensive PBKDF2 only for survivors.
2. **PBKDF2 workload drops drastically** (e.g., 256× to 4096× fewer calls).
3. **Highly parallelizable:** HMAC tests scale linearly in GPU/OpenCL kernels.
4. **Deterministic versioning:** filters only seeds matching the target derivation path.

---

## 6) Conceptual GPU/OpenCL Pipeline

* **Kernel 1 — HMAC triage**
  Compute HMAC-SHA512 with Electrum version key → select seeds matching prefix bits.

* **Kernel 2 — PBKDF2 derivation**
  Run PBKDF2 (2048 iterations) for approved seeds; derive public keys or addresses.

* **Validation phase:**
  Compare derived outputs with known address or xpub target; record metrics.

---

## 7) Assumptions and Limitations

* Applies to **Electrum v2** (12/24 words). Prefix length `k` may vary by implementation.
* No additional passphrase or seed extension assumed.
* $\rho$ is an estimate; real GPU/CPU performance may differ.
* This paper models **feasibility**, not exploitation.

---

## 8) References

* **BIP-39:** Mnemonic encoding, entropy, and checksum spec.
* **Electrum Codebase:** Seed version handling, HMAC version checks.
* **PBKDF2-HMAC-SHA512:** Cryptographic cost estimation.
* **OpenCL/CUDA:** Parallel kernel optimization for crypto workloads.

---

## 9) Conclusions

* Electrum’s pre-filter does **not** reduce total combinatorial entropy but **shifts the workload** to a smaller, verifiable subset.
* For typical segwit seeds ($k = 12$), PBKDF2 workload is **~256× smaller**.
* Considering all costs, **~85× overall speedup** is realistic on modern GPUs.
* The HMAC filter is the key to making large-scale Electrum seed recovery computationally feasible.

---

**Ethical Notice:**
This analysis supports **legitimate recovery** of wallets owned by the user. Unauthorized access to third-party wallets is **illegal and unethical**.
