#define ROTATE_RIGHT(x, n) ((x >> n) | (x << (64UL - n)))
#define ROTATE(x, y) (((x) >> (y)) | ((x) << (64 - (y))))

#define F1(x, y, z) (bitselect(z, y, x))
#define F0(x, y, z) (bitselect(x, y, ((x) ^ (z))))

#define rotl64(a, n) (rotate((a), (n)))
#define rotr64(a, n) (rotate((a), (64ul - n)))

#define SHA512_S0(x) (rotr64(x, 28ul) ^ rotr64(x, 34ul) ^ rotr64(x, 39ul))
#define SHA512_S1(x) (rotr64(x, 14ul) ^ rotr64(x, 18ul) ^ rotr64(x, 41ul))

inline ulong little_s0(ulong x) {
  return rotr64(x, 1ul) ^ rotr64(x, 8ul) ^ (x >> 7ul);
}

inline ulong little_s1(ulong x) {
  return rotr64(x, 19ul) ^ rotr64(x, 61ul) ^ (x >> 6ul);
}

#define SHA512_STEP(a, b, c, d, e, f, g, h, x, K)                              \
  {                                                                            \
    h += K + SHA512_S1(e) + F1(e, f, g) + x;                                   \
    d += h;                                                                    \
    h += SHA512_S0(a) + F0(a, b, c);                                           \
  }
#define ROUND_STEP_SHA512(i)                                                   \
  {                                                                            \
    SHA512_STEP(a, b, c, d, e, f, g, h, W[i + 0], K512[i + 0]);                \
    SHA512_STEP(h, a, b, c, d, e, f, g, W[i + 1], K512[i + 1]);                \
    SHA512_STEP(g, h, a, b, c, d, e, f, W[i + 2], K512[i + 2]);                \
    SHA512_STEP(f, g, h, a, b, c, d, e, W[i + 3], K512[i + 3]);                \
    SHA512_STEP(e, f, g, h, a, b, c, d, W[i + 4], K512[i + 4]);                \
    SHA512_STEP(d, e, f, g, h, a, b, c, W[i + 5], K512[i + 5]);                \
    SHA512_STEP(c, d, e, f, g, h, a, b, W[i + 6], K512[i + 6]);                \
    SHA512_STEP(b, c, d, e, f, g, h, a, W[i + 7], K512[i + 7]);                \
    SHA512_STEP(a, b, c, d, e, f, g, h, W[i + 8], K512[i + 8]);                \
    SHA512_STEP(h, a, b, c, d, e, f, g, W[i + 9], K512[i + 9]);                \
    SHA512_STEP(g, h, a, b, c, d, e, f, W[i + 10], K512[i + 10]);              \
    SHA512_STEP(f, g, h, a, b, c, d, e, W[i + 11], K512[i + 11]);              \
    SHA512_STEP(e, f, g, h, a, b, c, d, W[i + 12], K512[i + 12]);              \
    SHA512_STEP(d, e, f, g, h, a, b, c, W[i + 13], K512[i + 13]);              \
    SHA512_STEP(c, d, e, f, g, h, a, b, W[i + 14], K512[i + 14]);              \
    SHA512_STEP(b, c, d, e, f, g, h, a, W[i + 15], K512[i + 15]);              \
  }

#define COPY_EIGHT(dst, src)                                                   \
  (dst)[0] = (src)[0];                                                         \
  (dst)[1] = (src)[1];                                                         \
  (dst)[2] = (src)[2];                                                         \
  (dst)[3] = (src)[3];                                                         \
  (dst)[4] = (src)[4];                                                         \
  (dst)[5] = (src)[5];                                                         \
  (dst)[6] = (src)[6];                                                         \
  (dst)[7] = (src)[7];

#define FUNCAO_W1(i) W[i] = message[i]
#define FUNCAO_W2(i) W[i] = message[16 + i]
#define FUNCAO_W3(i) W[i] = message[block_idx * 16 + i]

#define ADJUST_DATA(a, b)                                                      \
  (a)[16] = (b)[0];                                                            \
  (a)[17] = (b)[1];                                                            \
  (a)[18] = (b)[2];                                                            \
  (a)[19] = (b)[3];                                                            \
  (a)[20] = (b)[4];                                                            \
  (a)[21] = (b)[5];                                                            \
  (a)[22] = (b)[6];                                                            \
  (a)[23] = (b)[7];                                                            \
  (a)[24] = 0x8000000000000000UL;                                              \
  (a)[31] = 1536UL;

static inline void sha512_hash_two_blocks_message(ulong *message, ulong *H) {

  ulong W[80];
  ulong a, b, c, d, e, f, g, h, i;
  ulong S0, S1, ch, maj, temp1, temp2, W_15, W_2;

  for (i = 0; i < 16; i++)
    FUNCAO_W1(i);

  for (int i = 16; i < 80; i++) {
    W[i] = W[i - 16] + little_s0(W[i - 15]) + W[i - 7] + little_s1(W[i - 2]);
  }

  a = H[0];
  b = H[1];
  c = H[2];
  d = H[3];
  e = H[4];
  f = H[5];
  g = H[6];
  h = H[7];

  ROUND_STEP_SHA512(0);
  ROUND_STEP_SHA512(16);
  ROUND_STEP_SHA512(32);
  ROUND_STEP_SHA512(48);
  ROUND_STEP_SHA512(64);

  H[0] += a, H[1] += b, H[2] += c, H[3] += d, H[4] += e, H[5] += f, H[6] += g,
      H[7] += h;

  for (i = 0; i < 16; i++)
    FUNCAO_W2(i);

  for (i = 16; i < 80; i++) {
    W[i] = W[i - 16] + little_s0(W[i - 15]) + W[i - 7] + little_s1(W[i - 2]);
  }

  a = H[0];
  b = H[1];
  c = H[2];
  d = H[3];
  e = H[4];
  f = H[5];
  g = H[6];
  h = H[7];

  ROUND_STEP_SHA512(0);
  ROUND_STEP_SHA512(16);
  ROUND_STEP_SHA512(32);
  ROUND_STEP_SHA512(48);
  ROUND_STEP_SHA512(64);

  H[0] += a;
  H[1] += b;
  H[2] += c;
  H[3] += d;
  H[4] += e;
  H[5] += f;
  H[6] += g;
  H[7] += h;
}

static inline void PBKDF2_ROUND(ulong *UX, ulong *inner_H, ulong *U,
                                ulong *inner_data, ulong *outer_data,
                                ulong *T) {
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

void hmac_sha512_long(ulong *inner_data, ulong *outer_data, ulong *J) {
  inner_data[16] = 7885351518267664739UL;
  inner_data[17] = 6442450944UL;
  inner_data[18] = 0, inner_data[19] = 0, inner_data[20] = 0,
  inner_data[21] = 0, inner_data[22] = 0, inner_data[23] = 0,
  inner_data[24] = 0, inner_data[25] = 0, inner_data[26] = 0,
  inner_data[27] = 0, inner_data[28] = 0, inner_data[29] = 0,
  inner_data[30] = 0, inner_data[31] = 1120UL;

  ulong inner_H[8];
  INIT_SHA512(inner_H);
  sha512_hash_two_blocks_message(inner_data, inner_H);
  ADJUST_DATA(outer_data, inner_H);
  sha512_hash_two_blocks_message(outer_data, J);
}

void hmac_prepare(ulong *key, uchar key_len, ulong *inner_data,
                  ulong *outer_data) {

  uchar key_ulongs = (key_len + 7) / 8;
#pragma loop pipeline(enable)
#pragma cl_kernel_vectorize_enable
#pragma INDEPENDENT
#pragma OPENCL INDEPENDENT
  for (; key_ulongs > 0; --key_ulongs) {
    inner_data[key_ulongs - 1] = key[key_ulongs - 1] ^ 0x3636363636363636UL;
    outer_data[key_ulongs - 1] = key[key_ulongs - 1] ^ 0x5C5C5C5C5C5C5C5CUL;
  }
}

void pbkdf2_hmac_sha512_long(ulong *password, uchar password_len, ulong *T) {
  ulong inner_data[32] = {
      0x3636363636363636UL, 0x3636363636363636UL, 0x3636363636363636UL,
      0x3636363636363636UL, 0x3636363636363636UL, 0x3636363636363636UL,
      0x3636363636363636UL, 0x3636363636363636UL, 0x3636363636363636UL,
      0x3636363636363636UL, 0x3636363636363636UL, 0x3636363636363636UL,
      0x3636363636363636UL, 0x3636363636363636UL, 0x3636363636363636UL,
      0x3636363636363636UL, 0x3636363636363636UL, 0x3636363636363636UL,
      0x3636363636363636UL, 0x3636363636363636UL, 0x3636363636363636UL,
      0x3636363636363636UL, 0x3636363636363636UL, 0x3636363636363636UL};
  ulong outer_data[32] = {
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL};

  hmac_prepare(password, password_len, inner_data, outer_data);
  hmac_sha512_long(inner_data, outer_data, T);

  ulong UX[8];
  ulong U[8];

  COPY_EIGHT(U, T);
  ulong inner_H[8];
#pragma nounroll
#pragma loop dependence(enable)
  for (int i = 1; i < 2048; ++i) {
    PBKDF2_ROUND(UX, inner_H, U, inner_data, outer_data, T);
  }
}