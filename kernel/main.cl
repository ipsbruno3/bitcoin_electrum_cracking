#define NUM_WORDS 2048
#define SEED_SIZE 12

__kernel void generate_combinations(__global uint *index, __global ulong *seed, ulong batchsize, __global ulong *output)
{
  int idx = get_global_id(0);

  ulong seed_max = seed[0];
  ulong seed_min = seed[1] + (idx * batchsize);
  ulong final = batchsize;

  /*
    uchar message[] = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    uchar key[] = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

    ulong key_long[32] = {0};
    ulong message_long[32] = {0};
    ulong out[8] = {0, 0, 0, 0, 0, 0, 0, 0, 0};
    ulong hmac[8] = {H0_SHA512, H1_SHA512, H2_SHA512, H3_SHA512, H4_SHA512, H5_SHA512, H6_SHA512, H7_SHA512};

    uchar_to_ulong(key, strlen(key), key_long);
    uchar_to_ulong(message, strlen(message), message_long);
    hmac_sha512_long(key_long, strlen(key), message_long, strlen(message), hmac);
    DEBUG_ARRAY("HMAC512 Resultado key", hmac, 8);
    pbkdf2_hmac_sha512_long(key_long, strlen(key), out);
    DEBUG_ARRAY("Resultado key", out, 8);
  */

  uint indices[12] = {0};
  indices[0] = (seed_max & (2047UL << 53UL)) >> 53UL;
  indices[1] = (seed_max & (2047UL << 42UL)) >> 42UL;
  indices[2] = (seed_max & (2047UL << 31UL)) >> 31UL;
  indices[3] = (seed_max & (2047UL << 20UL)) >> 20UL;
  indices[4] = (seed_max & (2047UL << 9UL)) >> 9UL;
  indices[5] = (((seed_max << 55UL) >> 53UL)) | (((seed_min & (3UL << 62UL)) >> 62UL));
  indices[6] = (seed_min & (2047UL << 51UL)) >> 51UL;
  uchar seed_char[128];
  for (ulong iterator = 0; iterator < final; ++iterator, seed_min++)
  {
    indices[7] = (seed_min & (2047UL << 40UL)) >> 40UL;
    indices[8] = (seed_min & (2047UL << 29UL)) >> 29UL;
    indices[9] = (seed_min & (2047UL << 18UL)) >> 18UL;
    indices[10] = (seed_min & (2047UL << 7UL)) >> 7UL;
    indices[11] = ((seed_min << 57UL) >> 53UL) | sha256_from_ulong(seed_max, seed_min) >> 4;

    uchar mnemonic[127] = {0};
    ulong seed[16] = {0,0,0,0,0,0,0,0};
    uchar mnemonic_length = 11 + word_lengths[indices[0]] + word_lengths[indices[1]] + word_lengths[indices[2]] + word_lengths[indices[3]] + word_lengths[indices[4]] + word_lengths[indices[5]] + word_lengths[indices[6]] + word_lengths[indices[7]] + word_lengths[indices[8]] + word_lengths[indices[9]] + word_lengths[indices[10]] + word_lengths[indices[11]];
    int mnemonic_index = 0;

    for (int i = 0; i < 12; i++)
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
    mnemonic[mnemonic_index - 1] = 0;

    ulong resultado_pbkdf2[8];
    uchar_to_ulong(mnemonic, mnemonic_length, seed);
    pbkdf2_hmac_sha512_long(seed, mnemonic_length, resultado_pbkdf2);

    if (seed_min % 1000000 == 0)
    {
      printf("\n\nSEED: %s\nLEN: %d\n", mnemonic, mnemonic_length);
      DEBUG_ARRAY("PBKDF2: ", resultado_pbkdf2, 8);
      DEBUG_ARRAY("MNEMONIC SEED: ", seed, 16);
    }
  }
}
