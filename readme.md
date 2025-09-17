# 🚀 Bitcoin Seed Recovery with OpenCL  

This project demonstrates the optimization of OpenCL kernels to recover Bitcoin **BIP-39 mnemonics** when only **7 out of 12 words** are known. The challenge required exploring a search space of **2.25 quadrillion combinations** with maximum GPU efficiency.  

---

## 🎯 Problem  

Reconstructing the missing 5 words of a BIP-39 mnemonic (including checksum validation) involves:  

- **Search space**: 2.25 × 10^15 possibilities  
- **Target**: Efficient validation of candidate seeds at scale  

Through aggressive kernel optimization (memory efficiency, loop unrolling, reduced overhead), a **RTX 4090 Ti** achieved over **2 million seed validations per second**.  

---

## ⚡ Performance Benchmarks  

| GPU Model              | Speed (seeds/sec) |
|-------------------------|-------------------|
| RTX 4090               | 1.8M |
| RTX 4080 Super         | 1.0M |
| RTX 4070 Ti Super      | 750K |
| RTX 4060 Ti            | 400K |
| RTX 3060 Ti            | 300K |
| RTX 3060               | 230K |
| GTX 1070               | 80K  |

---

## 🛠️ Key Optimizations  

1. **Multi-Address Hash Check**  
   Hash maps enable constant-time (`O(1)`) checks against multiple candidate addresses.  

2. **Bit-Masked Mnemonic Representation**  
   Mnemonics are stored as `ulong` bitmasks instead of strings, drastically reducing overhead.  

3. **Loop Unrolling**  
   SHA-256 inner loops are unrolled with conditional checks removed, reducing per-iteration cost.  

4. **Optimized SHA-512 Buffers**  
   Reduced loop iterations from 128 → 16 per block using compact `ulong` arrays.  

5. **Vectorized Operations**  
   Leveraging 8–16 byte vector copies for faster memory transfers.  

6. **Precomputation of Fixed Words (To-Do)**  
   Cache SHA-512/SHA-256 of the 7 known words to avoid redundant work.  

7. **Python Multi-threading for Resource Control**  
   Python orchestrates memory management and database handling across GPUs.  

---

## 🚀 Results  

- **Throughput**: Up to **12B SHA-256 ops/sec** and **3B SHA-512 ops/sec** with tuned kernels.  
- **Memory Efficiency**: Compact data structures and reduced buffer sizes.  
- **Scalability**: Kernels scale linearly across multiple GPUs.  

---

## 🔮 Next Steps  

1. **Multi-GPU Support** – enable distributed workloads across GPUs for linear scaling.  
2. **Address Derivation & Comparison** – implement BIP-32/BIP-44 derivation to generate addresses and match against user-provided or blockchain data.  

---

## 🌟 Conclusion  

This project highlights the potential of **GPU acceleration** and **low-level kernel optimization** for solving cryptographic search problems at massive scale.  

Contributions, ideas, and improvements are welcome!  

---

**Bruno da Silva**  
Security Researcher  
📧 bsbruno[@]proton.me  
2024  
