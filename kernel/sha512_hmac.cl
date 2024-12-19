#define ROTATE_RIGHT(x, n) ((x >> n) | (x << (64UL - n)))

#define FUNCAO(i)                                                              \
  W_15 = W[i - 15], W_2 = W[i - 2],                                            \
  W[i] = W[i - 16] +                                                           \
         (ROTATE_RIGHT(W_15, 1UL) ^ ROTATE_RIGHT(W_15, 8UL) ^ (W_15 >> 7UL)) +       \
         W[i - 7] +                                                            \
         (ROTATE_RIGHT(W_2, 19UL) ^ ROTATE_RIGHT(W_2, 61UL) ^ (W_2 >> 6UL))



inline void INIT_SHA512(ulong *a) {
    a[0] = 0x6a09e667f3bcc908UL;
    a[1] = 0xbb67ae8584caa73bUL;
    a[2] = 0x3c6ef372fe94f82bUL;
    a[3] = 0xa54ff53a5f1d36f1UL;
    a[4] = 0x510e527fade682d1UL;
    a[5] = 0x9b05688c2b3e6c1fUL;
    a[6] = 0x1f83d9abfb41bd6bUL;
    a[7] = 0x5be0cd19137e2179UL;
}
inline void COPY_EIGHT(ulong *dst, const ulong *src) {
    dst[0] = src[0];
    dst[1] = src[1];
    dst[2] = src[2];
    dst[3] = src[3];
    dst[4] = src[4];
    dst[5] = src[5];
    dst[6] = src[6];
    dst[7] = src[7];
}


#define FUNCAO_SHA(i)                                                          \
  temp1 = h +                                                                  \
          (ROTATE_RIGHT(e, 14) ^ ROTATE_RIGHT(e, 18) ^ ROTATE_RIGHT(e, 41)) +  \
          ((e & f) ^ (~e & g)) + K512[i] + W[i];                               \
  temp2 = (ROTATE_RIGHT(a, 28) ^ ROTATE_RIGHT(a, 34) ^ ROTATE_RIGHT(a, 39)) +  \
          ((a & b) ^ (a & c) ^ (b & c)),                                       \
  h = g, g = f, f = e, e = d + temp1, d = c, c = b, b = a, a = temp1 + temp2

#define FUNCAO_W1(i) W[i] = message[i]
#define FUNCAO_W2(i) W[i] = message[16 + i]

inline void ADJUST_DATA(ulong *a, const ulong *b) {
    a[16] = b[0];
    a[17] = b[1];
    a[18] = b[2];
    a[19] = b[3];
    a[20] = b[4];
    a[21] = b[5];
    a[22] = b[6];
    a[23] = b[7];
    a[24] = 0x8000000000000000UL;
    a[31] = 1536UL;
}

inline void sha512_hash_two_blocks_message(ulong *message, ulong *H) {

  ulong W[80];
  ulong a, b, c, d, e, f, g, h;
  ulong S0, S1, ch, maj, temp1, temp2, W_15, W_2;

  FUNCAO_W1(0), FUNCAO_W1(1), FUNCAO_W1(2), FUNCAO_W1(3), FUNCAO_W1(4),
      FUNCAO_W1(5), FUNCAO_W1(6), FUNCAO_W1(7), FUNCAO_W1(8), FUNCAO_W1(9),
      FUNCAO_W1(10), FUNCAO_W1(11), FUNCAO_W1(12), FUNCAO_W1(13), FUNCAO_W1(14),
      FUNCAO_W1(15);

  FUNCAO(16), FUNCAO(17), FUNCAO(18), FUNCAO(19), FUNCAO(20), FUNCAO(21),
      FUNCAO(22), FUNCAO(23), FUNCAO(24), FUNCAO(25), FUNCAO(26), FUNCAO(27),
      FUNCAO(28), FUNCAO(29), FUNCAO(30), FUNCAO(31), FUNCAO(32), FUNCAO(33),
      FUNCAO(34), FUNCAO(35), FUNCAO(36), FUNCAO(37), FUNCAO(38), FUNCAO(39),
      FUNCAO(40), FUNCAO(41), FUNCAO(42), FUNCAO(43), FUNCAO(44), FUNCAO(45),
      FUNCAO(46), FUNCAO(47), FUNCAO(48), FUNCAO(49), FUNCAO(50), FUNCAO(51),
      FUNCAO(52), FUNCAO(53), FUNCAO(54), FUNCAO(55), FUNCAO(56), FUNCAO(57),
      FUNCAO(58), FUNCAO(59), FUNCAO(60), FUNCAO(61), FUNCAO(62), FUNCAO(63),
      FUNCAO(64), FUNCAO(65), FUNCAO(66), FUNCAO(67), FUNCAO(68), FUNCAO(69),
      FUNCAO(70), FUNCAO(71), FUNCAO(72), FUNCAO(73), FUNCAO(74), FUNCAO(75),
      FUNCAO(76), FUNCAO(77), FUNCAO(78), FUNCAO(79);

  a = H[0], b = H[1], c = H[2], d = H[3], e = H[4], f = H[5], g = H[6],
  h = H[7];

  FUNCAO_SHA(0), FUNCAO_SHA(1), FUNCAO_SHA(2), FUNCAO_SHA(3), FUNCAO_SHA(4),
      FUNCAO_SHA(5), FUNCAO_SHA(6), FUNCAO_SHA(7), FUNCAO_SHA(8), FUNCAO_SHA(9),
      FUNCAO_SHA(10), FUNCAO_SHA(11), FUNCAO_SHA(12), FUNCAO_SHA(13),
      FUNCAO_SHA(14), FUNCAO_SHA(15), FUNCAO_SHA(16), FUNCAO_SHA(17),
      FUNCAO_SHA(18), FUNCAO_SHA(19), FUNCAO_SHA(20), FUNCAO_SHA(21),
      FUNCAO_SHA(22), FUNCAO_SHA(23), FUNCAO_SHA(24), FUNCAO_SHA(25),
      FUNCAO_SHA(26), FUNCAO_SHA(27), FUNCAO_SHA(28), FUNCAO_SHA(29),
      FUNCAO_SHA(30), FUNCAO_SHA(31), FUNCAO_SHA(32), FUNCAO_SHA(33),
      FUNCAO_SHA(34), FUNCAO_SHA(35), FUNCAO_SHA(36), FUNCAO_SHA(37),
      FUNCAO_SHA(38), FUNCAO_SHA(39), FUNCAO_SHA(40), FUNCAO_SHA(41),
      FUNCAO_SHA(42), FUNCAO_SHA(43), FUNCAO_SHA(44), FUNCAO_SHA(45),
      FUNCAO_SHA(46), FUNCAO_SHA(47), FUNCAO_SHA(48), FUNCAO_SHA(49),
      FUNCAO_SHA(50), FUNCAO_SHA(51), FUNCAO_SHA(52), FUNCAO_SHA(53),
      FUNCAO_SHA(54), FUNCAO_SHA(55), FUNCAO_SHA(56), FUNCAO_SHA(57),
      FUNCAO_SHA(58), FUNCAO_SHA(59), FUNCAO_SHA(60), FUNCAO_SHA(61),
      FUNCAO_SHA(62), FUNCAO_SHA(63), FUNCAO_SHA(64), FUNCAO_SHA(65),
      FUNCAO_SHA(66), FUNCAO_SHA(67), FUNCAO_SHA(68), FUNCAO_SHA(69),
      FUNCAO_SHA(70), FUNCAO_SHA(71), FUNCAO_SHA(72), FUNCAO_SHA(73),
      FUNCAO_SHA(74), FUNCAO_SHA(75), FUNCAO_SHA(76), FUNCAO_SHA(77),
      FUNCAO_SHA(78), FUNCAO_SHA(79);

  H[0] += a, H[1] += b, H[2] += c, H[3] += d, H[4] += e, H[5] += f, H[6] += g,
      H[7] += h;

  FUNCAO_W2(0), FUNCAO_W2(1), FUNCAO_W2(2), FUNCAO_W2(3), FUNCAO_W2(4),
      FUNCAO_W2(5), FUNCAO_W2(6), FUNCAO_W2(7), FUNCAO_W2(8), FUNCAO_W2(9),
      FUNCAO_W2(10), FUNCAO_W2(11), FUNCAO_W2(12), FUNCAO_W2(13), FUNCAO_W2(14),
      FUNCAO_W2(15);

  FUNCAO(16), FUNCAO(17), FUNCAO(18), FUNCAO(19), FUNCAO(20), FUNCAO(21),
      FUNCAO(22), FUNCAO(23), FUNCAO(24), FUNCAO(25), FUNCAO(26), FUNCAO(27),
      FUNCAO(28), FUNCAO(29), FUNCAO(30), FUNCAO(31), FUNCAO(32), FUNCAO(33),
      FUNCAO(34), FUNCAO(35), FUNCAO(36), FUNCAO(37), FUNCAO(38), FUNCAO(39),
      FUNCAO(40), FUNCAO(41), FUNCAO(42), FUNCAO(43), FUNCAO(44), FUNCAO(45),
      FUNCAO(46), FUNCAO(47), FUNCAO(48), FUNCAO(49), FUNCAO(50), FUNCAO(51),
      FUNCAO(52), FUNCAO(53), FUNCAO(54), FUNCAO(55), FUNCAO(56), FUNCAO(57),
      FUNCAO(58), FUNCAO(59), FUNCAO(60), FUNCAO(61), FUNCAO(62), FUNCAO(63),
      FUNCAO(64), FUNCAO(65), FUNCAO(66), FUNCAO(67), FUNCAO(68), FUNCAO(69),
      FUNCAO(70), FUNCAO(71), FUNCAO(72), FUNCAO(73), FUNCAO(74), FUNCAO(75),
      FUNCAO(76), FUNCAO(77), FUNCAO(78), FUNCAO(79);

  a = H[0], b = H[1], c = H[2], d = H[3], e = H[4], f = H[5], g = H[6],
  h = H[7];

  FUNCAO_SHA(0), FUNCAO_SHA(1), FUNCAO_SHA(2), FUNCAO_SHA(3), FUNCAO_SHA(4),
      FUNCAO_SHA(5), FUNCAO_SHA(6), FUNCAO_SHA(7), FUNCAO_SHA(8), FUNCAO_SHA(9),
      FUNCAO_SHA(10), FUNCAO_SHA(11), FUNCAO_SHA(12), FUNCAO_SHA(13),
      FUNCAO_SHA(14), FUNCAO_SHA(15), FUNCAO_SHA(16), FUNCAO_SHA(17),
      FUNCAO_SHA(18), FUNCAO_SHA(19), FUNCAO_SHA(20), FUNCAO_SHA(21),
      FUNCAO_SHA(22), FUNCAO_SHA(23), FUNCAO_SHA(24), FUNCAO_SHA(25),
      FUNCAO_SHA(26), FUNCAO_SHA(27), FUNCAO_SHA(28), FUNCAO_SHA(29),
      FUNCAO_SHA(30), FUNCAO_SHA(31), FUNCAO_SHA(32), FUNCAO_SHA(33),
      FUNCAO_SHA(34), FUNCAO_SHA(35), FUNCAO_SHA(36), FUNCAO_SHA(37),
      FUNCAO_SHA(38), FUNCAO_SHA(39), FUNCAO_SHA(40), FUNCAO_SHA(41),
      FUNCAO_SHA(42), FUNCAO_SHA(43), FUNCAO_SHA(44), FUNCAO_SHA(45),
      FUNCAO_SHA(46), FUNCAO_SHA(47), FUNCAO_SHA(48), FUNCAO_SHA(49),
      FUNCAO_SHA(50), FUNCAO_SHA(51), FUNCAO_SHA(52), FUNCAO_SHA(53),
      FUNCAO_SHA(54), FUNCAO_SHA(55), FUNCAO_SHA(56), FUNCAO_SHA(57),
      FUNCAO_SHA(58), FUNCAO_SHA(59), FUNCAO_SHA(60), FUNCAO_SHA(61),
      FUNCAO_SHA(62), FUNCAO_SHA(63), FUNCAO_SHA(64), FUNCAO_SHA(65),
      FUNCAO_SHA(66), FUNCAO_SHA(67), FUNCAO_SHA(68), FUNCAO_SHA(69),
      FUNCAO_SHA(70), FUNCAO_SHA(71), FUNCAO_SHA(72), FUNCAO_SHA(73),
      FUNCAO_SHA(74), FUNCAO_SHA(75), FUNCAO_SHA(76), FUNCAO_SHA(77),
      FUNCAO_SHA(78), FUNCAO_SHA(79);

  H[0] += a, H[1] += b, H[2] += c, H[3] += d, H[4] += e, H[5] += f, H[6] += g,
      H[7] += h;
}

inline void sha512_hash_large_message(ulong *message, uchar total_blocks, ulong *H) {

  ulong W[80];
  ulong a, b, c, d, e, f, g, h;
  ulong S0, S1, ch, maj, temp1, temp2, W_15, W_2;

  for (uchar block_idx = 0; block_idx < total_blocks; block_idx++) {

    for (uchar i = 0; i < 16; i++) {
      W[i] = message[block_idx * 16 + i];
    }

    FUNCAO(16);
    FUNCAO(17);
    FUNCAO(18);
    FUNCAO(19);
    FUNCAO(20);
    FUNCAO(21);
    FUNCAO(22);
    FUNCAO(23);
    FUNCAO(24);
    FUNCAO(25);
    FUNCAO(26);
    FUNCAO(27);
    FUNCAO(28);
    FUNCAO(29);
    FUNCAO(30);
    FUNCAO(31);
    FUNCAO(32);
    FUNCAO(33);
    FUNCAO(34);
    FUNCAO(35);
    FUNCAO(36);
    FUNCAO(37);
    FUNCAO(38);
    FUNCAO(39);
    FUNCAO(40);
    FUNCAO(41);
    FUNCAO(42);
    FUNCAO(43);
    FUNCAO(44);
    FUNCAO(45);
    FUNCAO(46);
    FUNCAO(47);
    FUNCAO(48);
    FUNCAO(49);
    FUNCAO(50);
    FUNCAO(51);
    FUNCAO(52);
    FUNCAO(53);
    FUNCAO(54);
    FUNCAO(55);
    FUNCAO(56);
    FUNCAO(57);
    FUNCAO(58);
    FUNCAO(59);
    FUNCAO(60);
    FUNCAO(61);
    FUNCAO(62);
    FUNCAO(63);
    FUNCAO(64);
    FUNCAO(65);
    FUNCAO(66);
    FUNCAO(67);
    FUNCAO(68);
    FUNCAO(69);
    FUNCAO(70);
    FUNCAO(71);
    FUNCAO(72);
    FUNCAO(73);
    FUNCAO(74);
    FUNCAO(75);
    FUNCAO(76);
    FUNCAO(77);
    FUNCAO(78);
    FUNCAO(79);

    a = H[0];
    b = H[1];
    c = H[2];
    d = H[3];
    e = H[4];
    f = H[5];
    g = H[6];
    h = H[7];

    FUNCAO_SHA(0);
    FUNCAO_SHA(1);
    FUNCAO_SHA(2);
    FUNCAO_SHA(3);
    FUNCAO_SHA(4);
    FUNCAO_SHA(5);
    FUNCAO_SHA(6);
    FUNCAO_SHA(7);
    FUNCAO_SHA(8);
    FUNCAO_SHA(9);
    FUNCAO_SHA(10);
    FUNCAO_SHA(11);
    FUNCAO_SHA(12);
    FUNCAO_SHA(13);
    FUNCAO_SHA(14);
    FUNCAO_SHA(15);
    FUNCAO_SHA(16);
    FUNCAO_SHA(17);
    FUNCAO_SHA(18);
    FUNCAO_SHA(19);
    FUNCAO_SHA(20);
    FUNCAO_SHA(21);
    FUNCAO_SHA(22);
    FUNCAO_SHA(23);
    FUNCAO_SHA(24);
    FUNCAO_SHA(25);
    FUNCAO_SHA(26);
    FUNCAO_SHA(27);
    FUNCAO_SHA(28);
    FUNCAO_SHA(29);
    FUNCAO_SHA(30);
    FUNCAO_SHA(31);
    FUNCAO_SHA(32);
    FUNCAO_SHA(33);
    FUNCAO_SHA(34);
    FUNCAO_SHA(35);
    FUNCAO_SHA(36);
    FUNCAO_SHA(37);
    FUNCAO_SHA(38);
    FUNCAO_SHA(39);
    FUNCAO_SHA(40);
    FUNCAO_SHA(41);
    FUNCAO_SHA(42);
    FUNCAO_SHA(43);
    FUNCAO_SHA(44);
    FUNCAO_SHA(45);
    FUNCAO_SHA(46);
    FUNCAO_SHA(47);
    FUNCAO_SHA(48);
    FUNCAO_SHA(49);
    FUNCAO_SHA(50);
    FUNCAO_SHA(51);
    FUNCAO_SHA(52);
    FUNCAO_SHA(53);
    FUNCAO_SHA(54);
    FUNCAO_SHA(55);
    FUNCAO_SHA(56);
    FUNCAO_SHA(57);
    FUNCAO_SHA(58);
    FUNCAO_SHA(59);
    FUNCAO_SHA(60);
    FUNCAO_SHA(61);
    FUNCAO_SHA(62);
    FUNCAO_SHA(63);
    FUNCAO_SHA(64);
    FUNCAO_SHA(65);
    FUNCAO_SHA(66);
    FUNCAO_SHA(67);
    FUNCAO_SHA(68);
    FUNCAO_SHA(69);
    FUNCAO_SHA(70);
    FUNCAO_SHA(71);
    FUNCAO_SHA(72);
    FUNCAO_SHA(73);
    FUNCAO_SHA(74);
    FUNCAO_SHA(75);
    FUNCAO_SHA(76);
    FUNCAO_SHA(77);
    FUNCAO_SHA(78);
    FUNCAO_SHA(79);

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

inline void sha512_hash_with_padding(ulong *message, uchar message_len_bytes,
                              ulong *H) {
  ushort message_len_ulongs = (message_len_bytes + 7) / 8;
  uchar blocks = ((message_len_bytes % 128 + 17) <= 128)
                     ? (message_len_bytes / 128 + 1)
                     : (message_len_bytes / 128 + 2);

  ulong padded_message[32] = {0};

  for (uchar i = 0; i < message_len_ulongs; i++) {
    padded_message[i] = message[i];
  }

  uchar last_byte_index = message_len_bytes % 8;
  if (last_byte_index == 0) {
    padded_message[message_len_ulongs] = 0x8000000000000000UL;
  } else {
    padded_message[message_len_ulongs - 1] |=
        (0x80UL << (56UL - last_byte_index * 8UL));
  }

  padded_message[blocks * 16 - 1] = (ulong)(message_len_bytes * 8);

  sha512_hash_large_message(padded_message, blocks, H);
}

__constant static const ulong mnemonic_salt[] = {0x6d6e656d6f6e6963UL, 0x0000000100000000UL};

void hmac_sha512_long(ulong *inner_data, ulong *outer_data, ulong *J) {
  inner_data[16] = mnemonic_salt[0];
  inner_data[17] = mnemonic_salt[1];
  ulong inner_H[8];
  INIT_SHA512(inner_H);
  sha512_hash_with_padding(inner_data, 140, inner_H);
  ADJUST_DATA(outer_data, inner_H);
  sha512_hash_two_blocks_message(outer_data, J);
}

void hmac_prepare(ulong *key, uchar key_len, ulong *inner_data, ulong *outer_data) {

  uchar key_ulongs = (key_len + 7) / 8;
#pragma unroll
  for (uchar i = 0; i < key_ulongs; i++) {
    inner_data[i] = key[i] ^ 0x3636363636363636UL;
    outer_data[i] = key[i] ^ 0x5C5C5C5C5C5C5C5CUL;
  }
#pragma unroll
  for (uchar i = key_ulongs; i < 24; i++) {
    inner_data[i] = 0x3636363636363636UL;
    outer_data[i] = 0x5C5C5C5C5C5C5C5CUL;
  }
}

void pbkdf2_hmac_sha512_long(ulong *password, uchar password_len, ulong *T) {
  ulong inner_data[32];
  ulong outer_data[32];

  hmac_prepare(password, password_len, inner_data, outer_data);
  hmac_sha512_long(inner_data, outer_data, T);

  ulong UX[8];
  ulong U[8];


  COPY_EIGHT(U, T);
  ulong inner_H[8];

  for (int i = 1; i < 2048; i++) {
    INIT_SHA512(UX);
    INIT_SHA512(inner_H);
    ADJUST_DATA(inner_data, U);
    sha512_hash_two_blocks_message(inner_data, inner_H);
    ADJUST_DATA(outer_data, inner_H);
    sha512_hash_two_blocks_message(outer_data, UX);
    T[0] ^= UX[0];
    T[1] ^= UX[1];
    T[2] ^= UX[2];
    T[3] ^= UX[3];
    T[4] ^= UX[4];
    T[5] ^= UX[5];
    T[6] ^= UX[6];
    T[7] ^= UX[7];
    COPY_EIGHT(U, UX);
  }
}