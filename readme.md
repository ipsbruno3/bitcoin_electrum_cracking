
#  Bitcoin OpenCL Brute Force BIP39
# 20 Million Hashes Per Second 🚀 

  This is a specially optimized version for hashing and retrieving the last 6 mnemonic words for Bitcoin. The function compiles and optimizes SHA-256 and SHA-512 calculations directly on the processor, avoiding non-essential loops and optimizing cryptography without declaring additional or extra functions.





 
 

### Features🌟

✅ Windows Application Management
Easily manage the tool through a Windows environment, ensuring seamless setup and operation. 

✅ Sequential Seed Generation
Implements a robust sequential algorithm to generate and iterate over billions of BIP-39 mnemonic combinations with high efficiency.

  
✅ Optimized GPU SHA-256 Kernel
Leverages OpenCL to maximize GPU computational capabilities for performing SHA-256 hashing, crucial for Bitcoin cryptographic validation.

  ❌ GPU-Accelerated SHA-512 and PBKDF2 Integration (In Progress)
Extending GPU optimization to include SHA-512 and PBKDF2 (Password-Based Key Derivation Function 2), essential components for deriving Bitcoin master keys from seeds.

❌ Seed Derivation and Blockchain Address Matching (Coming Soon). Adding a mechanism to compare derived wallet addresses with clustered blockchain data for practical validation and attack scenarios.

  
  
  
  

## 💡 Performance Highlights

Thanks to extensive kernel optimizations and strategic variable tuning, the tool achieves an astounding performance of:

  

**7 billions valid seeds per second** on a standard laptop with no dedicated GPU.

Potential scalability to far exceed this rate with high-end GPUs, taking full advantage of parallelism in cryptographic functions.

This performance is achieved through:

  

Efficient memory usage, leveraging OpenCL constant memory for key storage.

Streamlined hashing pipeline to minimize bottlenecks.

Modular architecture to allow future expansions.

  
  

 

## Work in Progress 📅

  

🔄 SHA-512 and PBKDF2 Optimization
Implementing GPU-accelerated versions of these functions to unlock greater efficiency in seed-to-master-key derivation.

  

🔄 Blockchain Address Matching
Developing a clustering mechanism to identify and match derived wallet addresses with real-world blockchain data.

  

🔄 Scalability Enhancements
Refactoring the codebase for seamless deployment on large-scale GPU clusters to explore new possibilities in brute force computations.

  
  

## 🔧 Technical Details

This project relies heavily on OpenCL for GPU parallelization and is structured with the following goals:

  

Minimize memory overhead by utilizing shared and constant memory regions.

  

Streamline cryptographic operations to eliminate unnecessary computational cycles.

  

Modularize code for quick adoption of new cryptographic standards or seed derivation techniques with bitwise operators

  
# 🚀 Why So Fast?

Our tools use the smallest amount of memory possible. For example, for wallets, we work directly bit by bit instead of strings, ensuring efficiency.

![image](https://github.com/user-attachments/assets/dfd58093-697e-4da5-a2d6-6a5b436b5af2)

The `sha256` function is designed to process only one byte at a time, saving processing resources and making the system lighter.

![image](https://github.com/user-attachments/assets/4e4a0b35-bc38-4e90-85bc-f16db26a75e0)

Our goal is to map trillions of Bitcoin wallets in just a few days. This code successfully processes the first 11 seeds, defining the last one using a checksum with 1 chance in 128 (not 2048).

![image](https://github.com/user-attachments/assets/417b4a00-e2f7-47ba-a808-51f514adae0e)

We have optimized the maximum number of loops to make the code more fluid and efficient.

![image](https://github.com/user-attachments/assets/ec580647-bdda-4ec9-ba44-646dbbb129b8)

Before building our `pbkdf2 hmac sha512`, we precomputed `INNER_PAD` and `OUTER_PAD` to maximize efficiency.

---

## 📖 How It Works

1. **Efficiency with Bits and Bytes**:
   - Working directly with bits saves memory and improves performance.
   - Processing byte by byte reduces the overhead of string manipulation.

2. **Wallet Mapping**:
   - We reduced the search space by limiting the checksum to 1 in 128 combinations.
   - This is crucial for processing large volumes of wallets quickly.

3. **Precomputing Pads for PBKDF2**:
   - Precomputing `INNER_PAD` and `OUTER_PAD` avoids repetitive calculations.
   - The process becomes linear and faster.

4. **Optimized Loops**:
   - Reducing unnecessary cycles and optimizing parallelism (when possible) improves scalability.

Our code is designed to map Bitcoin wallets efficiently, making the most of the available resources.


1. Generate Mnemonic Seeds: Sequentially generates billions of BIP-39 mnemonic combinations in accordance with Bitcoin standards.

2. Checksum SHA-256 Hashing: Computes cryptographic hashes of the seeds using an optimized GPU kernel for unmatched speed.

3. Seed Validation and Derivation: Filters and processes valid seeds for further operations, such as deriving wallet addresses.

4. Address Comparison (Upcoming): Matches derived addresses with a clustered blockchain database for potential hits.

  
  
  

Stay updated for more developments as we continue refining this powerful tool! 👨‍💻✨