
#define 128 128
#define ROTR(x, n) ((x >> n) | (x << (64 - n)))

#define SHA512_INIT {                             \
    0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL, \
    0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL, \
    0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL, \
    0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL}


__constant ulong SHA512_INIT_ARRAY[8] = {
    0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
    0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
    0x510e527fade682d1, 0x9b05688c2b3e6c1f,
    0x1f83d9abfb41bd6b, 0x5be0cd19137e2179};


__constant ulong K[80] = {
    0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc,
    0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118,
    0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
    0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235, 0xc19bf174cf692694,
    0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
    0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
    0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4,
    0xc6e00bf33da88fc2, 0xd5a79147930aa725, 0x06ca6351e003826f, 0x142929670a0e6e70,
    0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
    0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
    0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30,
    0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
    0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8,
    0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3,
    0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
    0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b,
    0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178,
    0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
    0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c,
    0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817};

inline uchar to_hex_char(uint value)
{
  return value < 10 ? ('0' + value) : ('a' + value - 10);
}

void sha512_hash_large_message(ulong *message, uint total_blocks, ulong *H)
{
  ulong W[80] = {0};
  ulong a, b, c, d, e, f, g, h;
  ulong S0, S1, ch, maj, temp1, temp2;

  for (uint block_idx = 0; block_idx < total_blocks; block_idx++)
  {
#pragma unroll
    for (uint i = 0; i < 16; i++)
    {
      W[i] = message[block_idx * 16 + i];
    }
#pragma unroll
    for (uint i = 16; i < 80; i++)
    {
      W[i] = W[i - 16] + (rotate_right(W[i - 15], 1) ^ rotate_right(W[i - 15], 8) ^ (W[i - 15] >> 7)) + W[i - 7] + (rotate_right(W[i - 2], 19) ^ rotate_right(W[i - 2], 61) ^ (W[i - 2] >> 6));
    }
    a = H[0];
    b = H[1];
    c = H[2];
    d = H[3];
    e = H[4];
    f = H[5];
    g = H[6];
    h = H[7];

#pragma unroll
    for (uint i = 0; i < 80; i++)
    {
      temp1 = h + (rotate_right(e, 14) ^ rotate_right(e, 18) ^ rotate_right(e, 41)) + ((e & f) ^ (~e & g)) + K[i] + W[i];
      temp2 = (rotate_right(a, 28) ^ rotate_right(a, 34) ^ rotate_right(a, 39)) + ((a & b) ^ (a & c) ^ (b & c));

      h = g;
      g = f;
      f = e;
      e = d + temp1;
      d = c;
      c = b;
      b = a;
      a = temp1 + temp2;
    }
    H[0] += a;
    H[1] += b;
    H[2] += c;
    H[3] += d;
    H[4] += e;
    H[5] += f;
    H[6] += g;
    H[7] += h;
  }
}

// HMAC-SHA512 Implementation
void hmac_sha512(const ulong *key, uint key_len, const ulong *message, uint message_len, ulong *output)
{
  ulong key_block[32] = {0}; // Key block
  ulong ipad[32];            // Inner pad
  ulong opad[32];            // Outer pad
  ulong inner_hash[8];                               // Inner hash result
  ulong temp_hash[8];                                // Temporary hash
  uint blocks = 2;
  ulong inner_message[32];
  ulong outer_message[32];

  // Adjust or hash the key
  if (key_len > 128)
  {
    sha512_hash_large_message(key, key_len / sizeof(ulong), key_block);
    key_len = 64; // SHA-512 hash size in bytes
  }
  else
  {
    for (uint i = 0; i < 128 / sizeof(ulong); i++)
    {
      key_block[i] = (i < key_len / sizeof(ulong)) ? key[i] : 0;
    }
  }

  // Create ipad and opad
  for (uint i = 0; i < 16; i++)
  {
    ipad[i] = key_block[i] ^ 0x3636363636363636ULL;
    opad[i] = key_block[i] ^ 0x5c5c5c5c5c5c5c5cULL;
  }

  // Inner hash
  for (uint i = 0; i < 128 / sizeof(ulong); i++)
  {
    inner_message[i] = ipad[i];
  }
  for (uint i = 0; i < blocks; i++)
  {
    inner_message[128 / sizeof(ulong) + i] = (i < blocks) ? message[i] : 0;
  }
  sha512_hash_large_message(inner_message, 128 / sizeof(ulong) + blocks, inner_hash);

  // Outer hash
  for (uint i = 0; i < 128 / sizeof(ulong); i++)
  {
    outer_message[i] = opad[i];
  }
  for (uint i = 0; i < 8; i++)
  {
    outer_message[128 / sizeof(ulong) + i] = inner_hash[i];
  }
  sha512_hash_large_message(outer_message, 128 / sizeof(ulong) + 8, temp_hash);

  // Copy result to output
  for (uint i = 0; i < 8; i++)
  {
    output[i] = temp_hash[i];
  }
}

// Test Function
void test_pbkdf()
{
  ulong key[] = {0x12345678abcdef00ULL, 0xdeadbeef12345678ULL, 0xabcdefabcdefabcdefULL};
  uint key_len = sizeof(key);
  ulong message[] = {0xabcdefabcdefabcdefULL, 0x1234567812345678ULL};
  uint message_len = sizeof(message);
  ulong output[8];

  hmac_sha512(key, key_len, message, message_len, output);

  for (int i = 0; i < 8; i++)
  {
    printf("%016lx ", output[i]);
  }
  printf("\n");
}
