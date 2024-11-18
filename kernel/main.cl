#define NUM_WORDS 2048
#define SEED_SIZE 12

void load_words_to_private(__global uchar *wordlist, uchar words[2048][11], ushort word_lengths[2048])
{
  for (int i = 0; i < NUM_WORDS; i++)
  {
    for (int j = 0; j < 11; j++)
    {
      words[i][j] = (uchar)wordlist[i * 11 + j];
      word_lengths[i] = strlen(words[i]);
    }
    words[i][10] = '\0';
  }
}

void sha512_test()
{
  uchar input[] = "fb9cac76f2c1445ac89913c6533e5c20ac9995e46065fb9cac76f2c1445ac89913c6533e5c20ac9995e46065b5ad9eafb9cac76f2c1445ac89913c6533e5c20ac9995e46065b5ad9eafb9cac76f2c1445ac89913c6533e5c20ac9995e46065b5ad9eab5ad9ea",
        expected[] = "2ecf8b1da9d56b0b104cd1641fce200c69b3d5080ac5acdfa75578d61c5335a5be64a5aa4c7d4714b1a54d42b0f8c9e9819d7a82e6074529f7fadd0e643ca718", result[128];
  ulong H[8] = SHA512_INIT, output[16];
  uchar outcmp[128];
  uint sucesso = 1;
  uchar_to_ulong(input, strlen(input), output);

  sha512_hash_with_padding(output, strlen(input), H);
  ulong_array_to_char(H, 8, outcmp);

  DEBUG_ARRAY("SHA512", H, 8);
}

void test_hmac_sha512_long()
{
  ulong H[8] = {
      0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL,
      0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
      0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL,
      0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL};

  uchar input[] = "18a7e6e543cf91303cb48215070d38f22f142d2a59d6e048ee58e2ed7c229d931854e5329e4461ef9a00d4109e4bb17adec";
  ulong password[32] = {0};
  uchar esperado[] = "598973ee89a2992e5275a33c73a6320c4cd04e38789dc829808a6638f63477eccd49c83f79f5e30810e89d73e05465e93389b57f260ef0c8347feb16808a2220";
  ulong salt[32] = {0};
  uint output_len = 0;

  uchar_to_ulong(input, strlen(input), password);
  uchar_to_ulong(input, strlen(input), salt);
  hmac_sha512_long(password, strlen(input), salt, strlen(input), H);

  printf("HMAC-SHA512:");
  hash_to_hex_string(H);
  // printf("Esperado: %s \n", esperado);
}

__kernel void generate_combinations(__global uint *index, __global uchar *wordlist, __global ulong *seed, ulong batchsize, __global ulong2 *output)
{
  int idx = get_global_id(0);

  uchar words[2048][11];
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

  for (ulong iterator = 0; iterator < final; ++iterator, seed_min++)
  {
    indices[7] = (seed_min & (2047UL << 40UL)) >> 40UL;
    indices[8] = (seed_min & (2047UL << 29UL)) >> 29UL;
    indices[9] = (seed_min & (2047UL << 18UL)) >> 18UL;
    indices[10] = (seed_min & (2047UL << 7UL)) >> 7UL;
    indices[11] = ((seed_min << 57UL) >> 53UL);
  }
  sha512_test();
  // test_uchar_to_ulong();
  test_pbkdf2_hmac_sha512();
  // test_hmac_sha512_long();
}
