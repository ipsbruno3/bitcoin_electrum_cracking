#define SHA512_INIT {                             \
    0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL, \
    0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL, \
    0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL, \
    0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL}

__constant static const ulong K[80] = {
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
  ulong W[80];
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

void sha512_hash_with_padding(ulong *message, uint message_len_bytes, ulong *H)
{
  uint blocks = ((message_len_bytes % 128 + 17) <= 128)
                    ? (message_len_bytes / 128) + 1
                    : (message_len_bytes / 128) + 2;
  ulong padded_message[5 * 16] = {0};
  uint message_len_ulongs = (message_len_bytes + 7) / 8;
  for (uint i = 0; i < message_len_ulongs; i++)
  {
    padded_message[i] = message[i];
  }
  uint last_byte_index = message_len_bytes % 8;
  if (last_byte_index == 0)
  {
    padded_message[message_len_ulongs] = 0x8000000000000000ULL;
  }
  else
  {
    padded_message[message_len_ulongs - 1] |= (0x80ULL << (56 - last_byte_index * 8));
  }
  padded_message[blocks * 16 - 1] = (ulong)(message_len_bytes * 8);
  sha512_hash_large_message(padded_message, blocks, H);
}

/*
void hmac_sha512_long(ulong *key, uint key_len, ulong *message, uint message_len, ulong *J)
{
  ulong key_block[64] = {0};
  ulong inner_data[64] = {0};
  ulong outer_data[64] = {0};
  ulong inner_H[8] = SHA512_INIT;
  uint key_ulongs = (key_len + 7) / 8;
  for (uint i = 0; i < key_ulongs; i++)
  {
    key_block[i] = key[i];
  }
  for (uint i = 0; i < 16; i++)
  {
    inner_data[i] = key_block[i] ^ 0x3636363636363636ULL;
    outer_data[i] = key_block[i] ^ 0x5C5C5C5C5C5C5C5CULL;
  }
  uint message_ulongs = (message_len + 7) / 8;
  for (uint i = 0; i < message_ulongs; i++)
  {
    inner_data[16 + i] = message[i];
  }
  uint inner_message_len_bytes = 128 + message_len;
  sha512_hash_with_padding(inner_data, inner_message_len_bytes, inner_H);
  for (uint i = 0; i < 8; i++)
  {
    outer_data[16 + i] = inner_H[i];
  }
  sha512_hash_with_padding(outer_data, 192, J);
}
*/

void hmac_sha512_long(ulong *key, uint key_len, ulong *message, uint message_len, ulong *output)
{
  ulong key_block[16] = SHA512_INIT;

  ulong inner_data[32] = {0};
  ulong outer_data[32] = {0};
  ulong inner_H[8] = SHA512_INIT;

  if (key_len > 128)
  {
    sha512_hash_with_padding(key, key_len, key_block); 
  }
  else
  {
    for (uint i = 0; i < 16; i++)
    {
      key_block[i] = 0;
    }
    for (uint i = 0; i < (key_len + 7) / 8; i++)
    {
      key_block[i] = key[i];
    }
  }
  for (uint i = 0; i < 16; i++)
  {
    inner_data[i] = key_block[i] ^ 0x3636363636363636ULL;
    outer_data[i] = key_block[i] ^ 0x5C5C5C5C5C5C5C5CULL; 
  }
  uint message_ulongs = (message_len + 7) / 8;
  for (uint i = 0; i < message_ulongs; i++)
  {
    inner_data[16 + i] = message[i];
  }
  uint inner_message_len_bytes = 128 + message_len;
  sha512_hash_with_padding(inner_data, inner_message_len_bytes, inner_H);
  uchar inner_H_uchar[64] = {0};
  ulong_to_uchar(inner_H, 8, inner_H_uchar);
  for (uint i = 0; i < 8; i++)
  {
    outer_data[16 + i] = inner_H[i];
  }
  sha512_hash_with_padding(outer_data, 128 + 64, output);
}



void pbkdf2_hmac_sha512(ulong *password, uint password_len, uint iterations, uint dklen, ulong *output)
{
  ulong F[8] = SHA512_INIT;
  ulong T[8];
  ulong salt_with_block[32] = {0};
  uint blocks = (dklen + 63) / 64; 
  uchar mnemonic[] = "mnemonic";
  uint salt_len = sizeof(mnemonic) - 1;

  uchar_to_ulong(mnemonic, salt_len, salt_with_block);
  for (uint i = 1; i <= blocks; i++)
  {
    salt_with_block[1] = 0x0000000000000001ULL;

    hmac_sha512_long(password, password_len, salt_with_block, salt_len + 8, F);

    for (uint k = 0; k < 8; k++)
    {
      T[k] = F[k];
    }

    for (uint j = 1; j < iterations; j++)
    {
      ulong U[8] = SHA512_INIT;

      hmac_sha512_long(password, password_len, F, 64, U);

      for (uint k = 0; k < 8; k++)
      {
        T[k] ^= U[k];
        F[k] = U[k];
      }
    }

    for (uint k = 0; k < 8 && (i - 1) * 64 + k * 8 < dklen; k++)
    {
      uint remaining_bytes = dklen - (i - 1) * 64;
      if (remaining_bytes >= 8)
      {
        output[(i - 1) * 8 + k] = T[k];
      }
      else
      {
        ulong mask = ~(0xFFFFFFFFFFFFFFFFULL >> (remaining_bytes * 8));
        output[(i - 1) * 8 + k] &= mask;
        output[(i - 1) * 8 + k] |= T[k] & ~mask;
      }
    }
  }
}




void test_pbkdf2_hmac_sha512()
{
  uchar password[] = "password";
  ulong password_converted[32] = {0};
  ulong output[32] = {0};
  uchar esperado[] = "f66872a6ab16966e3c739ea851b7eb0fe5bfd8bc9073fb9045b7338d3be7e50b195282fd4cd4b00bafc48a5974d8ccaf2b1e56f0c15abe9f6d87321fda767363";
  uchar_to_ulong(password, 8, password_converted);
  pbkdf2_hmac_sha512(password_converted, strlen(password), 2, 64, output);

  printf("PBKDF2-HMAC-SHA512 OUTPUT:\n");
  for (int i = 0; i < 8; i++)
  {
    printf("%016lx ", output[i]);
  }
  printf("\nEsperado: %s\n", esperado);
}



void test_uchar_to_ulong()
{
  uchar password[] = "password";
  uchar salt[] = "salt";
  ulong password_converted[32] = {0};
  ulong salt_converted[32] = {0};

  uint password_len = strlen(password);
  uint salt_len = strlen(salt);      
  uchar_to_ulong(password, password_len, password_converted);
  uchar_to_ulong(salt, salt_len, salt_converted);

  if (password_converted[0] == 0x70617373776f7264UL)
  {
    printf("UCHAR_TO_ULONG APROVADO\n");
  }
}



void hash_to_hex_string(ulong *hash)
{
  printf("\n");
  for (int i = 0; i < 8; i++)
  {
    printf("%016lx", hash[i]);
  }
  printf("\n");
}

