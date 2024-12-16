#define NUM_WORDS 2048
#define SEED_SIZE 12

__kernel void generate_combinations(__global uint *indices_original, __global ulong *seed, ulong batchsize)
{
  int idx = get_global_id(0);

  ulong seed_max = seed[0];
  ulong seed_min = seed[1] + (idx * batchsize);
  ulong final = batchsize;
  ulong mnemonic_long[16];
  uchar mnemonic[128];
  uint indices[12];
  ulong resultado_pbkdf2[8];

  indices[0] = (seed_max & (2047UL << 53UL)) >> 53UL;
  indices[1] = (seed_max & (2047UL << 42UL)) >> 42UL;
  indices[2] = (seed_max & (2047UL << 31UL)) >> 31UL;
  indices[3] = (seed_max & (2047UL << 20UL)) >> 20UL;
  indices[4] = (seed_max & (2047UL << 9UL)) >> 9UL;
  indices[5] = (((seed_max << 55UL) >> 53UL)) | (((seed_min & (3UL << 62UL)) >> 62UL));
  indices[6] = (seed_min & (2047UL << 51UL)) >> 51UL;

  uint index = -1;
  for (int i = 0; i != 7; i++)
  {
    for (int j = 0; words[indices[i]][j] != '\0'; j++)
    {
      mnemonic[++index] = (uchar)words[indices[i]][j];
    }
    mnemonic[++index] = ' ';
  }

  for (ulong iterator = 0; iterator < final; ++iterator, seed_min++)
  {
    uint prefix_length = index;

    indices[7] = (seed_min & (2047UL << 40UL)) >> 40UL;
    indices[8] = (seed_min & (2047UL << 29UL)) >> 29UL;
    indices[9] = (seed_min & (2047UL << 18UL)) >> 18UL;
    indices[10] = (seed_min & (2047UL << 7UL)) >> 7UL;
    indices[11] = ((seed_min << 57UL) >> 53UL) | sha256_from_ulong(seed_max, seed_min) >> 4;

    for (int i = 7; i != 12; i++)
    {
      for (int j = 0; words[indices[i]][j] != '\0'; j++)
      {
        mnemonic[++prefix_length] = (uchar)words[indices[i]][j];
      }
      mnemonic[++prefix_length] = ' ';
    }
    mnemonic[prefix_length] = '\0';

    /*while (prefix_length < 128)
    {
      mnemonic[++prefix_length] = 0;
    }*/

    resultado_pbkdf2[0] = H0_SHA512;
    resultado_pbkdf2[1] = H1_SHA512;
    resultado_pbkdf2[2] = H2_SHA512;
    resultado_pbkdf2[3] = H3_SHA512;
    resultado_pbkdf2[4] = H4_SHA512;
    resultado_pbkdf2[5] = H5_SHA512;
    resultado_pbkdf2[6] = H6_SHA512;
    resultado_pbkdf2[7] = H7_SHA512;

    uchar_to_ulong(mnemonic, prefix_length, mnemonic_long);
    pbkdf2_hmac_sha512_long(mnemonic_long, prefix_length, resultado_pbkdf2);

    if (seed_min % 1000000 == 0)
    {
      printf("SEED: %s\n", mnemonic);

      DEBUG_ARRAY("PBKDF2: ", resultado_pbkdf2, 8);
      DEBUG_ARRAY("MNEMONIC SEED: ", mnemonic_long, 16);
    }
  }
}
