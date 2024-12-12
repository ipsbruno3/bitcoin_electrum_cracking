# 🚀 Optimized Bitcoin Seed Recovery Using OpenCL

This report details the optimization process for an OpenCL kernel designed to recover Bitcoin wallet seeds. The scenario involves reconstructing a **BIP-39 mnemonic** with only 7 out of the 12 words known. The challenge required handling a search space exceeding **2 quadrillion possibilities** while achieving extreme computational efficiency.

---

## 🎯 Problem Statement

Recovering the full 12-word BIP-39 mnemonic involves calculating all combinations for the remaining 5 words, including the checksum validation. The search space can be expressed as:

*2.251799813685248 × 10^15*

To tackle this challenge, aggressive optimizations were applied to the kernel, focusing on memory efficiency, loop unrolling, and minimizing computational overhead. The result was a **validation rate of 2 million seeds per second**.

---

## 🛠️ Key Optimizations

### 1. Efficient Mnemonic Representation with Bit Manipulation

Instead of treating mnemonics as strings, they are represented as **bit-masked indices** stored in `ulong` variables. This allowed faster calculations and reduced computational overhead. The indices are extracted using shifts and bitwise operations:

```c
int idx = get_global_id(0);

uchar words[2048 * 11];
ushort word_lengths[2048];

ulong seed_max = seed[0];
ulong seed_min = seed[1] + (idx * batchsize);
ulong final = batchsize;

load_words_to_private(wordlist, words, word_lengths);

ushort indices[12] = {0};

indices[0] = (seed_max & (2047UL << 53UL)) >> 53UL;
indices[1] = (seed_max & (2047UL << 42UL)) >> 42UL;
indices[2] = (seed_max & (2047UL << 31UL)) >> 31UL;
indices[3] = (seed_max & (2047UL << 20UL)) >> 20UL;
indices[4] = (seed_max & (2047UL << 9UL)) >> 9UL;
indices[5] = (((seed_max << 55UL) >> 53UL)) | (((seed_min & (3UL << 62UL)) >> 62UL));
indices[6] = (seed_min & (2047UL << 51UL)) >> 51UL;

for (ulong iterator = 0; iterator < final; ++iterator, seed_min++) {
    indices[7] = (seed_min & (2047UL << 40UL)) >> 40UL;
    indices[8] = (seed_min & (2047UL << 29UL)) >> 29UL;
    indices[9] = (seed_min & (2047UL << 18UL)) >> 18UL;
    indices[10] = (seed_min & (2047UL << 7UL)) >> 7UL;
    indices[11] = ((seed_min << 57UL) >> 53UL);
}
```

### 2. Loop Unrolling in SHA-256

The computation of SHA-256 was heavily optimized by unrolling loops and eliminating conditional checks. The final loop iteration was avoided, as only `H0/A` was required for validation.

```c
#pragma unroll
for (int i = 0; i < 63; ++i) {
    temp1 = h + ((ROTR_256(e, 6)) ^ (ROTR_256(e, 11)) ^ (ROTR_256(e, 25))) +
            ((e & f) ^ (~e & g)) + K_256[i] + w[i];
    temp2 = ((ROTR_256(a, 2)) ^ (ROTR_256(a, 13)) ^ (ROTR_256(a, 22))) +
            ((a & b) ^ (a & c) ^ (b & c));
    h = g;
    g = f;
    f = e;
    e = d + temp1;
    d = c;
    c = b;
    b = a;
    a = temp1 + temp2;
}

// Perform the last iteration manually
temp1 = h + ((ROTR_256(e, 6)) ^ (ROTR_256(e, 11)) ^ (ROTR_256(e, 25))) +
        ((e & f) ^ (~e & g)) + K_256[63] + w[63];
temp2 = ((ROTR_256(a, 2)) ^ (ROTR_256(a, 13)) ^ (ROTR_256(a, 22))) +
        ((a & b) ^ (a & c) ^ (b & c));
```


#### Impact of This Optimization:

-   By skipping one full loop iteration, we saved computational resources and reduced the number of instructions executed.
-   This small change, when executed across billions of iterations, results in significant performance gains.

#### 3. Optimized SHA-512 Memory Usage in 64 Bits
The SHA-512 implementation was optimized to operate on smaller memory buffers using ulong arrays. This reduced the loop execution from 128 iterations to just 8 per block, minimizing memory overhead while preserving accuracy.


```c
void sha512_hash_large_message(ulong *message, uint total_blocks, ulong *H) {
    ulong W[80] = {0};
    ulong a, b, c, d, e, f, g, h;

    for (uint block_idx = 0; block_idx < total_blocks; block_idx++) {
        #pragma unroll
        for (uint i = 0; i < 16; i++) {
            W[i] = message[block_idx * 16 + i];
        }
        #pragma unroll
        for (uint i = 16; i < 80; i++) {
            W[i] = W[i - 16]
```



#### 4. Preloaded Wordlist with HMAC Masking
The mnemonic wordlist was preloaded into memory, applying HMAC-SHA512 masks during the load phase. This reduced runtime overhead, allowing the PBKDF2 HMAC-SHA512 to operate directly on the prepared seed

```c
for (uint i = 0; i < 16; i++) {
    ipad[i] = key_block[i] ^ 0x3636363636363636ULL;
    opad[i] = key_block[i] ^ 0x5c5c5c5c5c5c5c5cULL;
}
```

#### 5. Pre-calculate the Hashes of the First 7 Fixed Words  
Since the first mnemonics remain unchanged, the SHA-512/SHA-256 values can be precomputed and reused. This eliminates the need for recalculating the same values repeatedly, effectively doubling the search speed.

#### 6. Compare Strings Character by Character  
When comparing strings, break the comparison as soon as a mismatched character is found. This avoids unnecessary comparisons for the entire string, saving a significant number of operations over time.

#### 7. Avoid Using Global Memory  
Global memory access is slow. Minimizing its usage improves overall performance by reducing memory latency during operations.

#### 8. Replace `strlen` with Precomputed Array Lengths  
Use arrays that already store the actual length of the wordlist strings. This avoids unnecessary iterations over strings and saves processing time.




## 🚀 Results

-   **Performance**: Achieved **12 billion seed validations per second in SH256**, leveraging GPU parallelism and aggressive kernel optimization.
-   **Memory Efficiency**: Reduced memory usage by consolidating data structures and minimizing array sizes.
-   **Scalability**: Fully parallelized OpenCL kernels are ready for multi-GPU setups to scale performance further.
**"Future Potential"** explicitly states the possibility of breaking 6 words from 12 words mnemonic, linking it to the advancements in the current performance 👀  
----------


## 🔮 Future Directions

1. **Add Multi-GPU Support**  
   Expand kernel support for multi-GPU configurations to further enhance scalability and processing speed. This will allow distributed workloads across multiple GPUs, increasing the validation throughput significantly.

2. **Address Derivation and Comparison**  
   Extend the implementation to not only perform PBKDF2-HMAC-SHA512 but also derive **public addresses** based on the user-defined derivation path (e.g., BIP-32 or BIP-44 standards). The derived addresses will then be compared against the user-provided Bitcoin or cryptocurrency address to identify the correct mnemonic.

   Steps for this feature:
   - Implement BIP-32/BIP-44 derivation logic after generating the master private key.
   - Derive child keys for the specified derivation path.
   - Compute public keys and addresses for each child key.
   - Compare derived addresses with the user-provided address to validate the mnemonic.

   This functionality will allow the recovery process to handle full address verification automatically, providing an end-to-end solution.

3. **Error Correction for Mnemonics**  
   Integrate error correction techniques to handle scenarios where the mnemonic provided by the user is partially corrupted or contains typographical errors. By leveraging fuzzy matching or probabilistic models, the system can suggest potential corrections for invalid mnemonic inputs.


----------

## 🌟 Conclusion

This project showcases the power of GPU acceleration and kernel optimization in solving computationally intensive challenges. With these techniques, we achieved unprecedented performance in Bitcoin seed recovery.

Feel free to contribute, suggest improvements, or open an issue if you have any ideas. Let's push the limits of what's possible together! 🚀


**Regards**


    Bruno da Silva
    Security Researcher
    2024

