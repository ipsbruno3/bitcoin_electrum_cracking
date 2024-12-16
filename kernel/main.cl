#define NUM_WORDS 2048
#define SEED_SIZE 12



__kernel void generate_combinations(__global uint *index, __global ulong *seed, ulong batchsize)
{

  int idx = get_global_id(0);


  ulong seed_max = seed[0];
  ulong seed_min = seed[1] + (idx * batchsize);
  ulong final = batchsize;

  uint indices[12] = {0};
  indices[0] = (seed_max & (2047UL << 53UL)) >> 53UL;
  indices[1] = (seed_max & (2047UL << 42UL)) >> 42UL;
  indices[2] = (seed_max & (2047UL << 31UL)) >> 31UL;
  indices[3] = (seed_max & (2047UL << 20UL)) >> 20UL;
  indices[4] = (seed_max & (2047UL << 9UL)) >> 9UL;
  indices[5] = (((seed_max << 55UL) >> 53UL)) | (((seed_min & (3UL << 62UL)) >> 62UL));
  indices[6] = (seed_min & (2047UL << 51UL)) >> 51UL;

  uchar mnemonic[128] = {0};
  ulong mnemonic_long[16] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};


  int mnemonic_index = 0;
#pragma unroll
  for (int i = 0; i < 7; i++)
  {
    int word_index = indices[i];
    int word_length = word_lengths[word_index];

    for (int j = 0; j < word_length; j++)
    {
      mnemonic[mnemonic_index] = words[word_index][j];
      mnemonic_index++;
    }
    mnemonic[mnemonic_index] = 32;
    mnemonic_index++;
  }

  ulong mnemonic_5c[24];
  mnemonic_5c[0] = word_values_mask5c[indices[0]]; mnemonic_5c[1] = 0x20 ^0x5C;
  mnemonic_5c[2] = word_values_mask5c[indices[1]]; mnemonic_5c[3] = 0x20 ^0x5C;
  mnemonic_5c[4] = word_values_mask5c[indices[2]]; mnemonic_5c[5] = 0x20 ^0x5C;
  mnemonic_5c[6] = word_values_mask5c[indices[3]]; mnemonic_5c[7] = 0x20 ^0x5C;
  mnemonic_5c[8] = word_values_mask5c[indices[4]]; mnemonic_5c[9] = 0x20 ^0x5C;
  mnemonic_5c[10] = word_values_mask5c[indices[5]]; mnemonic_5c[11] = 0x20 ^0x5C;
  mnemonic_5c[12] = word_values_mask5c[indices[6]]; mnemonic_5c[13] = 0x20 ^0x5C;

  ushort mnemonic_prefix_len = 11 + word_lengths[indices[0]] + word_lengths[indices[1]] + word_lengths[indices[2]] + word_lengths[indices[3]] + word_lengths[indices[4]] + word_lengths[indices[5]] + word_lengths[indices[6]];
  for (ulong iterator = 0; iterator < final; ++iterator, seed_min++)
  {
    indices[7] = (seed_min & (2047UL << 40UL)) >> 40UL;
    indices[8] = (seed_min & (2047UL << 29UL)) >> 29UL;
    indices[9] = (seed_min & (2047UL << 18UL)) >> 18UL;
    indices[10] = (seed_min & (2047UL << 7UL)) >> 7UL;
    indices[11] = ((seed_min << 57UL) >> 53UL) | sha256_from_ulong(seed_max, seed_min) >> 4;

    uint mnemonic_length = mnemonic_prefix_len + word_lengths[indices[7]] + word_lengths[indices[8]] + word_lengths[indices[9]] + word_lengths[indices[10]] + word_lengths[indices[11]];

    int mnemonic_index_ex = mnemonic_prefix_len;
#pragma unroll
    for (int i = 7; i < 12; i++)
    {
      int word_index = indices[i];
      int word_length = word_lengths[word_index];

      for (int j = 0; j < word_length; j++)
      {
        mnemonic[mnemonic_index_ex] = words[word_index][j];
        mnemonic_index_ex++;
      }
      mnemonic[mnemonic_index_ex] = 32;
      mnemonic_index_ex++;
    }
    mnemonic[mnemonic_index_ex - 1] = 0;

    ulong resultado_pbkdf2[8] = {H0_SHA512, H1_SHA512, H2_SHA512, H3_SHA512, H4_SHA512, H5_SHA512, H6_SHA512, H7_SHA512};
    uchar_to_ulong(mnemonic, mnemonic_length, mnemonic_long);
    pbkdf2_hmac_sha512_long(mnemonic_long, mnemonic_length, resultado_pbkdf2);

    if (seed_min % 1000000 == 0)
    {
      printf("\n\nSEED: %s\nLEN: %d\n", mnemonic, mnemonic_length);
      DEBUG_ARRAY("PBKDF2: ", resultado_pbkdf2, 8);
      DEBUG_ARRAY("MNEMONIC SEED: ", mnemonic_long, 16);
    }
  }
}
