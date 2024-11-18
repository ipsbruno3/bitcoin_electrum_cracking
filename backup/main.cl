#define NUM_WORDS 2048
#define SEED_SIZE 12

void load_words_to_private(__global char *wordlist, char words[2048][11], ushort word_lengths[2048])
{
  for (int i = 0; i < NUM_WORDS; i++)
  {
    for (int j = 0; j < 11; j++)
    {
      words[i][j] = (char)wordlist[i * 11 + j];
      word_lengths[i] = strlen(words[i]);
    }
    words[i][10] = '\0';
  }
}


void sha512_test() {
  uchar input[] = "abc", expected[] = "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f", result[128]; 
  ulong H[8] = SHA512_INIT, output[16];
  uchar outcmp[16]; 
  uint output_len = 0, sucesso = 1;
  uchar_to_ulong(input, strlen(input), output, &output_len); 
  
  sha512_hash_with_padding(output, strlen(input), H); 
  ulong_array_to_char(H, 16, outcmp); 

  for (int i = 0; i < 128; i++) {  if (outcmp[i] != expected[i]) { sucesso = 0; break; } } 
  printf("Hash: %s\nTeste: %s\n", outcmp, sucesso ? "APROVADO" : "FALHOU SHA512");
}




void test_hmac_sha512_long()
{
  ulong H[8] = {
      0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL,
      0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
      0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL,
      0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL};

  uchar input[] = "abandona abandona abandona abandona abandona abandona abandona abandona abandona abandona abandona abandona abandona";
  ulong password[32] = {0};
  ulong salt[32] = {0};
  uint output_len = 0;

  uchar_to_ulong(input, strlen(input), password, &output_len);
  uchar_to_ulong(input, strlen(input), salt, &output_len);
  hmac_sha512_long(password, strlen(input), salt, strlen(input), H);

  printf("HMAC-SHA512:");
  hash_to_hex_string(H);
}

__kernel void generate_combinations(__global uint *index, __global char *wordlist, __global ulong *seed, ulong batchsize, __global ulong2 *output)
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

  test_pbkdf2_hmac_sha512();
  test_hmac_sha512_long();
}
