/*
 *    Optimized PBKDF2-HMAC-SHA512 for Mnemonic Generation
 *    ------------------------------------------------------
 *    This function implements PBKDF2 using HMAC-SHA512 in a highly optimized manner.
 *    It leverages precomputed HMAC masks (provided via inner_data and outer_data, which are
 *    initialized as gInnerData and gOuterData) to minimize the number of instructions required.
 *
 *    Technical Details:
 *      1. Pre-initialized HMAC strings: The input strings already include the initial HMAC masks and firsts size/padded sha512
 *         reducing the need for additional XOR operations.
 *      2. Individual SHA-512 Block Processing: Each SHA-512 block is processed separately to minimize overhead.
 *      3. Efficient Reuse of Temporary Buffers: Intermediate arrays (GU, OU, and U) are reused across the
 *         2048 iterations, thus optimizing memory usage and throughput.
 *      4. Manual Padding Setup: Padding values (e.g., inner_data[24] = 0x8000000000000000UL, inner_data[31] = 1536UL)
 *         are explicitly set to ensure proper SHA-512 block formatting.
 *
 *    Overall, this implementation achieves one of the most efficient PBKDF2 solutions available for
 *    Bitcoin mnemonic generation by significantly reducing instruction count and memory operations.
 *    https://github.com/ipsbruno
 */


void pbkdf2_hmac_sha512_long(ulong *inner_data, ulong *outer_data, ulong *T) {
  ulong U[8], OU[8], GU[8];
  INIT_SHA512(GU);
  INIT_SHA512(OU);

  sha512_procces(inner_data, GU);
  sha512_procces(outer_data, OU);
  COPY_EIGHT(U, GU);
  sha512_procces(inner_data + 16, U);
  COPY_EIGHT(outer_data + 16, U);
  COPY_EIGHT(T, OU);
  sha512_procces(outer_data + 16, T);
  COPY_EIGHT(U, T);
  inner_data[24] = 0x8000000000000000UL;
  inner_data[31] = 1536UL;
  COPY_EIGHT(outer_data + 16, T);
  for (ushort i = 1; i < 2048; ++i) {
    COPY_EIGHT(inner_data + 16, U);
    COPY_EIGHT(U, GU);
    sha512_procces(inner_data + 16, U);
    COPY_EIGHT(outer_data + 16, U);
    COPY_EIGHT(U, OU);
    sha512_procces(outer_data + 16, U);
    COPY_EIGHT_XOR(T, U);
  }
}
