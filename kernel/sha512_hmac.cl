

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
      W[i] = W[i - 16] +
             (rotate_right(W[i - 15], 1) ^ rotate_right(W[i - 15], 8) ^
              (W[i - 15] >> 7)) +
             W[i - 7] +
             (rotate_right(W[i - 2], 19) ^ rotate_right(W[i - 2], 61) ^
              (W[i - 2] >> 6));
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
      temp1 =
          h +
          (rotate_right(e, 14) ^ rotate_right(e, 18) ^ rotate_right(e, 41)) +
          ((e & f) ^ (~e & g)) + K512[i] + W[i];
      temp2 =
          (rotate_right(a, 28) ^ rotate_right(a, 34) ^ rotate_right(a, 39)) +
          ((a & b) ^ (a & c) ^ (b & c));

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
  uint message_len_ulongs = (message_len_bytes + 7) / 8;
  uint blocks = ((message_len_bytes % 128 + 17) <= 128)
                    ? (message_len_bytes / 128 + 1)
                    : (message_len_bytes / 128 + 2);

  ulong padded_message[128] = {0}; // Suporte para mensagens grandes

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
    padded_message[message_len_ulongs - 1] |=
        (0x80ULL << (56 - last_byte_index * 8));
  }

  padded_message[blocks * 16 - 1] = (ulong)(message_len_bytes * 8);

  sha512_hash_large_message(padded_message, blocks, H);
}

#define SHA512_BLOCK_SIZE 128
#define SHA512_HASH_SIZE 64

void hmac_sha512_long(ulong *key, uint key_len, ulong *message, uint message_len, ulong *J)
{
  ulong key_block[24] = {0};
  ulong inner_data[32] = {0};
  ulong outer_data[32] = {0};
  ulong inner_H[8] = {H0_SHA512, H1_SHA512, H2_SHA512, H3_SHA512, H4_SHA512, H5_SHA512, H6_SHA512, H7_SHA512};

  if (key_len > SHA512_BLOCK_SIZE)
  {
    ulong reduced_key[8] = {H0_SHA512, H1_SHA512, H2_SHA512, H3_SHA512, H4_SHA512, H5_SHA512, H6_SHA512, H7_SHA512};
    sha512_hash_with_padding(key, key_len, reduced_key);
    for (uint i = 0; i < 8; i++)
    {
      key_block[i] = reduced_key[i];
    }
    key_len = SHA512_HASH_SIZE;
  }
  else
  {
    uint key_ulongs = (key_len + 7) / 8;
    for (uint i = 0; i <= key_ulongs; i++)
    {
      key_block[i] = key[i];
    }
  }

  for (uint i = 0; i < 24; i++)
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

void pbkdf2_hmac_sha512_long(
    ulong *password, uint password_len,
    ulong *output)
{
  const ulong mnemonic_salt[] = {
      0x6d6e656d6f6e6963ULL, 
      0x0000000100000000ULL 
  };
  const uint salt_len = 2;
  const uint iterations = 2048;

  ulong U[8] = {H0_SHA512, H1_SHA512, H2_SHA512, H3_SHA512, H4_SHA512, H5_SHA512, H6_SHA512, H7_SHA512};
  ulong T[8];
  hmac_sha512_long(password, password_len, mnemonic_salt, 12, U);

  for (uint i = 0; i < 8; i++) {
    T[i] = U[i];
  }
  for (uint iteration = 1; iteration < iterations; iteration++)  {
    ulong UX[8] = {H0_SHA512, H1_SHA512, H2_SHA512, H3_SHA512, H4_SHA512, H5_SHA512, H6_SHA512, H7_SHA512};
    hmac_sha512_long(password, password_len, U, SHA512_HASH_SIZE, UX);
    for (uint i = 0; i < 8; i++)
    {
      T[i] ^= UX[i];
      U[i] = UX[i];
    }
  }
  for (uint i = 0; i < 8; i++)
  {
    output[i] = T[i];
  }
}
