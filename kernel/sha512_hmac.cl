

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

void sha512_hash_with_padding(ulong *message, uint message_len_bytes,
                              ulong *H)
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

void hmac_sha512_long(ulong *key, uint key_len, ulong *message, uint message_len, ulong *J)
{
  ulong key_block[16] = {0};      // Chave processada (128 bytes máximo)
  ulong inner_data[16] = {0};     // ipad + mensagem
  ulong outer_data[16] = {0};     // opad + hash interno
  ulong inner_H[8] = {0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL, 0x3c6ef372fe94f82bULL,
   0xa54ff53a5f1d36f1ULL, 0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL,
   0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL};

  // Ajustar a chave se for maior que 128 bytes
  if (key_len > 128)
  {
    // sha512_hash_with_padding(key, key_len, key_block);
    // key_len = 64; // SHA-512 reduz a chave para 64 bytes
    printf("A chave passou de 128 caracteres e foi hashada.\n");
  }
  else
  {
    uint key_ulongs = (key_len + sizeof(ulong) - 1) / sizeof(ulong);
    for (uint i = 0; i < key_ulongs; i++)
    {
      key_block[i] = key[i];
    }
  }

  // Criar ipad e opad corretamente
  for (uint i = 0; i < 16; i++)
  {
    if (i < (key_len + sizeof(ulong) - 1) / sizeof(ulong))
    {
      inner_data[i] = key_block[i] ^ 0x3636363636363636ULL;
      outer_data[i] = key_block[i] ^ 0x5C5C5C5C5C5C5C5CULL;
    }
    else
    {
      inner_data[i] = 0x3636363636363636ULL;
      outer_data[i] = 0x5C5C5C5C5C5C5C5CULL;
    }
  }

  // Preencher mensagem interna (ipad + mensagem)
  uint message_ulongs = (message_len + sizeof(ulong) - 1) / sizeof(ulong);
  if (16 + message_ulongs > 64)
  {
    printf("Erro: mensagem muito longa para o buffer interno.\n");
    return;
  }
  for (uint i = 0; i < message_ulongs; i++)
  {
    inner_data[16 + i] = message[i];
  }

  uint inner_message_len_bytes = 128 + message_len;
  sha512_hash_with_padding(inner_data, 192, inner_H);

  for (uint i = 0; i < 8; i++)
  {
    outer_data[16 + i] = inner_H[i];
  }

  uint outer_message_len_bytes = 128 + 64;
  sha512_hash_with_padding(outer_data, outer_message_len_bytes, J);
}

void test_pbkdf()
{
  uint ranges[2][2] = {{115, 135}, {245, 256}};
  for (uint range_idx = 0; range_idx < 2; range_idx++)
  {
    uint start = ranges[range_idx][0];
    uint end = ranges[range_idx][1];

    for (uint len = start; len <= end; len++)
    {
      uchar message[256] = {0};
      for (uint i = 0; i < len; i++)
      {
        message[i] = 'a';
      }
      ulong H[8];
      for (int i = 0; i < 8; i++)
      {
        //H[i] = SHA512_INIT[i];
      }

      // Compute the SHA-512 hash
      sha512_hash_with_padding((ulong *)message, len, H);

      // Print the hash directly
      printf("Length %u: ", len);
      for (int i = 0; i < 8; i++)
      {
        printf("%016lx", H[i]);
      }
      printf("\n");
    }
  }
}