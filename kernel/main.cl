#define FIX_SEED_STRING(i, idxs)                                               \
  {                                                                            \
    int j, p;                                                                  \
    for (j = 0, p = indices[(i)]; j < word_lengths[p];                         \
         j++, p = indices[(i)]) {                                              \
      mnemonic[(idxs)] = (uchar)words[p][j];                                   \
      (idxs)++;                                                                \
    }                                                                          \
    mnemonic[(idxs)] = ' ';                                                    \
    (idxs)++;                                                                  \
  }

__kernel void pbkdf2_hmac_sha512_test(__global uchar *py, __global uchar *input) {
  
  ulong mnemonic_long[32];
  ulong aa[8];
  uchar result[128];
  uchar_to_ulong(input, strlen(input), mnemonic_long, 0);
  INIT_SHA512(aa);
  pbkdf2_hmac_sha512_long(mnemonic_long, strlen(input), aa);
  ulong_array_to_char(aa, 8, result);

  if(strcmp(result, py)) {
    printf("\nIguais");
  } else {
    printf("\ndiferentes");
    printf("Veio de la: %s %s %s\n", input, result, py);
  }
}

__kernel void generate_combinations(__global ulong *seed, ulong batchsize, __global ulong * mnemonicLong, ulong lenOffset) {
  __private int idx = get_global_id(0);

  __private ulong seed_max = seed[0];
  __private ulong seed_min = seed[1] + (idx * batchsize);
  __private ulong final = batchsize;
  __private ulong mnemonic_long[16] ;
  __private uchar mnemonic[128] = "<TEMPLATE:PARTIAL_SEED>";
  __private uint indices[12];
  __private ulong pbkdf2[8];
  __private const uint index = lenOffset;

  uchar_to_ulong(mnemonic, lenOffset, mnemonic_long, 0);

  for (ulong iterator = 0; iterator < final; iterator++) {
    __private uchar prefix_length = index;

    indices[7] = (seed_min & (2047UL << 40UL)) >> 40UL;
    indices[8] = (seed_min & (2047UL << 29UL)) >> 29UL;
    indices[9] = (seed_min & (2047UL << 18UL)) >> 18UL;
    indices[10] = (seed_min & (2047UL << 7UL)) >> 7UL;
    indices[11] = ((seed_min << 57UL) >> 53UL) |
                  sha256_from_ulong(seed_max, seed_min) >> 4UL;

    FIX_SEED_STRING(7, prefix_length)
    FIX_SEED_STRING(8, prefix_length)
    FIX_SEED_STRING(9, prefix_length)
    FIX_SEED_STRING(10, prefix_length)
    FIX_SEED_STRING(11, prefix_length)

    mnemonic[prefix_length - 1] = '\0';
    int FINAL = prefix_length;

    while (prefix_length < 128) {
      mnemonic[prefix_length] = 0;
      prefix_length++;
    }
    
  uchar_to_ulong(mnemonic, FINAL, mnemonic_long, (lenOffset/8)-1);
    INIT_SHA512(pbkdf2);
    pbkdf2_hmac_sha512_long(mnemonic_long, prefix_length, pbkdf2);
    if (pbkdf2[0]==757476486) {
      printf("%s\n",
              mnemonic);
    }
    seed_min++;
  }
}
