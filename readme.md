
#  🚀  Bitcoin Electrum Seed Recovery (12 words | Last missing words) — Technical Analysis of the Version Pre-Filter (HMAC)


<img width="817" height="305" alt="ascii-art-text-removebg-preview" src="https://github.com/user-attachments/assets/b9808a4b-e950-44e9-bd22-4e74563598c1" />


🧬 **Bruno da Silva**  - Security Researcher — Blockchain & Cryptography  
---
📧 [bsbruno@proton.me](mailto:bsbruno@proton.me)  

📱 [+55 11 99740-2197](https://wa.me/5511997402197)  

🔗 [github.com/ipsbruno](https://github.com/ipsbruno)

🔗 [github.com/ipsbruno](https://github.com/ipsbrunoreserva)

🔗 [github.com/ipsbruno](https://github.com/ipsbruno3)

🔗 [pastebin.com/u/ipsBruno](https://pastebin.com/u/ipsBruno)

🔗 [pastebin.com/u/Drakins](https://pastebin.com/u/Drakins)

---



> **Scope:** Technical summary explaining how **Electrum v2 seeds** use an **HMAC pre-filter** that reduces brute-force complexity when recovering missing words from a 12-word mnemonic.   **Use:** For **legitimate self-recovery** only.



---

## 1)  Context and structural differences

- A 12-word mnemonic encodes 132 bits (11 bits per word).  
- Effective entropy: **128 bits** plus a **4-bit checksum** embedded in the final word. As a result, only **1 in 16** of raw 12-word sequences passes the BIP-39 checksum.  
- Seed derivation uses **PBKDF2-HMAC-SHA512** (typically 2048 iterations).

### Electrum v2 (12 or 24 words)
- Electrum seeds include an explicit **seed version/type** which is validated via an **HMAC-SHA512** operation keyed with a known label (commonly referenced as `Seed version` or equivalent). The HMAC output is checked against a small set of version prefixes that identify seed types (standard, segwit, 2FA, etc.).  
- Typical prefix probabilities observed in implementations: *Standard* types correspond to a small prefix (e.g., 1/256 chance by random), while *Segwit/2FA* types correspond to longer prefixes (e.g., 1/4096 chance by random). The exact prefix mapping is implementation dependent but the model below uses these representative values.  
- Electrum also uses **PBKDF2-HMAC-SHA512** (2048 iterations) to derive internal seed material from the mnemonic.

**Primary implication:** Electrum v2 enables a cheap, deterministic **pre-filter (1 HMAC per candidate)** that rejects the vast majority of incorrect candidates (for segwit seeds, approximately 4095/4096 of random candidates), before any expensive PBKDF2 work is performed. In contrast, BIP-39 requires PBKDF2 for all checksum-valid candidates.



## 2) 🔢 BIP-39 Keyspace Calculation

The formula for estimating the possible combinations of missing words in a BIP-39 mnemonic is:

$$
N_{BIP39}(u) = (2048^{(u-1)}) \times 128
$$

For example, for the last 5 words:

$$
N_{BIP39}(5) = (2048^4) \times 128 = 2^{51} = 2,251,799,813,685,248
$$

✅ **Final expression**

$$
\boxed{N_{BIP39}(5) = 2.25 ​​  quadrillion}] 
$$



## 3) 🔢 BIP-39 Electrum Keyspace Calculation

Electrum’s mnemonic validation model does not rely on the BIP-39 checksum.  
The raw candidate space with `u` unknown words is:

$$
N_{BIP39}(u) = (2048^{(u-1)}) \times 0.5
$$

---

#### Derivation for 5 unknown words

Substituting \( u = 5 \):

$$
N_{BIP39}(5) = (2048^{(5-1)}) \times 0.5 = (2048^4) \times 0.5
$$

Since \( 2048 = 2^{11} \):

$$
(2048^4) = (2^{11})^4 = 2^{44}
$$

Therefore:

$$
N_{BIP39}(5) = 2^{44} \times 0.5 = 2^{43}
$$

Numeric result:

$$
N_{BIP39}(5) = 8{,}796{,}093{,}022{,}208 \approx 8.8 \times 10^{12}
$$

---

✅ **Final expression**

$$
\boxed{N_{BIP39}(5) = 8.79trillion}
$$

---

## 3) Cost model: PBKDF2-HMAC-512 vs Pre-Filter HMAC

Define:
- \(C_H\) = cost of one HMAC-SHA512 operation.
- \(C_P\) = cost of one PBKDF2-HMAC-SHA512 (2048 iterations).

Approximate relation:

$$
\rho = \frac{C_P}{C_H} \approx 2048
$$

]

Since PBKDF2 with 2048 iterations effectively performs on the order of thousands of HMAC operations.

Let the probability that a raw candidate passes the Electrum version pre-filter be \(p_k = 2^{-k}\), where `k` is the number of prefix bits matched by the version prefix. Representative values:

- `k = 8` → probability \(p_k = 2^{-8} = 1/256\) (Standard approximate example).
- `k = 12` → probability \(p_k = 2^{-12} = 1/4096\) (Segwit/2FA representative example).


---

### 3.1 Theoretical speedup (cost ratio)

$$
\text{Speedup}(k)
= \frac{\text{Work}_{\text{BIP39}}(u)}{\text{Work}_{\text{Electrum}}(u,k)}
= \frac{2^{11u + 7}}{2^{11u}\big(1 + 2^{11 - k}\big)}
= \frac{128}{1 + 2^{11 - k}}
$$

- For `k = 12` (Segwit representative):

$$
\text{Speedup}(12)
= \frac{128}{1 + 2^{-1}}
= \frac{128}{1.5}
\approx 85.33\times
$$

- For `k = 8` (Standard representative):

$$
\text{Speedup}(8)
= \frac{128}{1 + 2^{3}}
= \frac{128}{9}
\approx 14.22\times
$$




Interpretation: Although Electrum’s HMAC pre-filter must be evaluated for every raw candidate, the dramatic reduction in downstream PBKDF2 calls yields a net total cost reduction. The exact factor depends on the version prefix length (`k`).

-
-''

## 4) Why Electrum’s pre-filter makes recovery feasible

1. **Two-stage computation**  
   - Stage A: cheap HMAC-SHA512 per raw candidate to check seed version prefix. This stage rejects the majority of incorrect candidates cheaply.  
   - Stage B: expensive PBKDF2 only for candidates that pass Stage A.

2. **Massive reduction of expensive PBKDF2 work**  
   - Compared to doing PBKDF2 for every checksum-valid candidate (BIP-39 flow), Electrum’s model cuts PBKDF2 invocations significantly (example: 256× <>4096x fewer PBKDF2 calls for the `u = 5`, segwit case for example).

3. **Parallel-friendly triage**  
   - The HMAC stage is highly parallelizable and maps well to GPU/OpenCL kernels with large batch sizes and minimal divergence. That makes it practical to scan huge raw candidate spaces quickly and only escalate a small fraction to the heavy PBKDF2 stage.

4. **Deterministic versioning reduces false positives**  
   - The seed version prefix ensures that only seeds corresponding to the expected derivation scheme (e.g., segwit) advance, minimizing wasted derivation and address validation checks.

---

## 5) High-level OpenCL pipeline (conceptual)  

**Design constraints:** present architecture only; no exploitable code detail.

- **Kernel 1 — HMAC triage:**  
  - Input: batched candidate mnemonics (as indices) converted to raw seed bytes.  
  - Operation: compute HMAC-SHA512 with the Electrum version key; test prefix bits.  
  - Output: compact list of indices for candidates that pass the prefix test.

- **Kernel 2 — PBKDF2 derivation:**  
  - Input: approved candidate indices from Kernel 1.  
  - Operation: PBKDF2-HMAC-SHA512 (2048 iterations) to compute internal seed; derive keys/addresses per the seed type.  
  - Output: derived public keys / addresses or hashes to validate.

- **Post-processing / validation:**  
  - Compare derived addresses/xpubs with known references (if available). Use GPU-resident Bloom filter/Hash tables  or CPU confirmation stage depending on memory and latency tradeoffs.

- **Telemetry / metrics:** report candidates/sec (HMAC), approvals/sec, PBKDF2/sec, and estimated time to completion. Use small sample runs to calibrate kernel throughput before full sweep.

---

## 6) Assumptions and limitations

- Analysis assumes **Electrum v2** seed model and representative prefix lengths (`k = 8` or `k = 12`). Implementations and exact prefix mappings may vary; always verify against the specific Electrum codebase/version in question.  
- This model assumes no extra passphrase or “seed extension” is present. If a passphrase exists, the search model changes fundamentally and the candidate space multiplies.  
- The analysis treats PBKDF2 cost as approximately proportional to its iteration count; real-world GPU/CPU performance should be measured and used to calibrate estimates.  
- This document is a cost and feasibility model; it does not provide exploit code or step-by-step instructions for unauthorized access.

---

## 7) References (implementation and standards to consult)
- Electrum seed/version handling and related implementation notes (Electrum codebase).  
- BIP-39 specification for mnemonic encoding and checksum behavior.  
- PBKDF2-HMAC-SHA512 behavior and iteration-based cost modeling.  
- OpenCL/CUDA best practices for cryptographic kernels and GPU batching.

(Consult the authoritative sources for exact constants, prefix maps and verification details in the Electrum release you target.)

---

## 8) Objective Conclusions
 
- Electrum v2 (segwit example with `k = 12`) reduces PBKDF2 invocations candidates **256×** reduction in PBKDF2 count.  
- Considering the full cost (HMAC triage + PBKDF2 on approved candidates), the aggregated cost reduction is on the order of **~85×** for a representative segwit prefix—i.e., the pre-filter materially reduces total computational expense, making large-scale parallel search far more practical under heavy parallelism (GPU clusters).  
- The pre-filter does not change the theoretical raw search space, but it shifts the heavy work into a much smaller fraction of candidates, which is the critical operational gain.

---

**Ethics reminder:** This analysis is provided to support legitimate recovery of one’s own wallets. Unauthorized access to others’ wallets is illegal and unethical.



