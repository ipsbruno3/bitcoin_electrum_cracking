
//
// #define UNROLL_FACTOR 16
/*
#define INIT_SHA512(a)                                                         \
  *(ulong8 *)a = (ulong8){0x6a09e667f3bcc908UL, 0xbb67ae8584caa73bUL,          \
                          0x3c6ef372fe94f82bUL, 0xa54ff53a5f1d36f1UL,          \
                          0x510e527fade682d1UL, 0x9b05688c2b3e6c1fUL,          \
                          0x1f83d9abfb41bd6bUL, 0x5be0cd19137e2179UL};
*/
#define INIT_SHA512(a)                                                         \
  (a)[0] = 0x6a09e667f3bcc908UL;                                               \
  (a)[1] = 0xbb67ae8584caa73bUL;                                               \
  (a)[2] = 0x3c6ef372fe94f82bUL;                                               \
  (a)[3] = 0xa54ff53a5f1d36f1UL;                                               \
  (a)[4] = 0x510e527fade682d1UL;                                               \
  (a)[5] = 0x9b05688c2b3e6c1fUL;                                               \
  (a)[6] = 0x1f83d9abfb41bd6bUL;                                               \
  (a)[7] = 0x5be0cd19137e2179UL;

__constant static const ulong K512[80] = {
    0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f,
    0xe9b5dba58189dbbc, 0x3956c25bf348b538, 0x59f111f1b605d019,
    0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242,
    0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
    0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,
    0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3,
    0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65, 0x2de92c6f592b0275,
    0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
    0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f,
    0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,
    0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc,
    0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
    0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6,
    0x92722c851482353b, 0xa2bfe8a14cf10364, 0xa81a664bbc423001,
    0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218,
    0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
    0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99,
    0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb,
    0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc,
    0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
    0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915,
    0xc67178f2e372532b, 0xca273eceea26619c, 0xd186b8c721c0c207,
    0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba,
    0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
    0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,
    0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a,
    0x5fcb6fab3ad6faec, 0x6c44198c4a475817};

#define Ch(x, y, z) (bitselect(z, y, x))
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
    h += K + SHA512_S1(e) + Ch(e, f, g) + x;                                   \
    d += h;                                                                    \
    h += SHA512_S0(a) + F0(a, b, c);                                           \
  }
#define ROUND_STEP_SHA512(a, b, c, d, e, f, g, h, W, i)                        \
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

#define COPY_EIGHT(dst, src) *(ulong8 *)(dst) = *(ulong8 *)(src)
#define COPY_DOUBLE_EIGHT(dst, src) *(ulong16 *)(dst) = *(ulong16 *)(src)

/*#define COPY_EIGHT(dst, src) \
  (dst)[0] = (src)[0];                                                         \
  (dst)[1] = (src)[1];                                                         \
  (dst)[2] = (src)[2];                                                         \
  (dst)[3] = (src)[3];                                                         \
  (dst)[4] = (src)[4];                                                         \
  (dst)[5] = (src)[5];                                                         \
  (dst)[6] = (src)[6];                                                         \
  (dst)[7] = (src)[7];
*/

#define ADJUST_DATA(a, b)                                                      \
  *(ulong8 *)(a + 16) = *(ulong8 *)(b);                                        \
  (a)[24] = 0x8000000000000000UL;                                              \
  (a)[31] = 1536UL;

static inline void sha512_procces(ulong *message, ulong *H) {

  ulong W[80];
  uchar i;
  ulong a, b, c, d, e, f, g, h;
  ulong S0, S1, ch, maj, temp1, temp2, W_15, W_2;

  COPY_DOUBLE_EIGHT(W, message);

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

  ROUND_STEP_SHA512(a, b, c, d, e, f, g, h, W, 0);
  ROUND_STEP_SHA512(a, b, c, d, e, f, g, h, W, 16);
  ROUND_STEP_SHA512(a, b, c, d, e, f, g, h, W, 32);
  ROUND_STEP_SHA512(a, b, c, d, e, f, g, h, W, 48);
  ROUND_STEP_SHA512(a, b, c, d, e, f, g, h, W, 64);

  H[0] += a, H[1] += b, H[2] += c, H[3] += d, H[4] += e, H[5] += f, H[6] += g,
      H[7] += h;
}

static inline void sha512_hash_two_blocks_message(ulong *message, ulong *H) {
  sha512_procces(message, H);
  sha512_procces(message + 16, H);
}

void pbkdf2_hmac_sha512_long(ulong *password, uchar password_len, ulong *T) {
  INIT_SHA512(T);

  ulong inner_data[32] = {0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          0x3636363636363636UL,
                          7885351518267664739UL,
                          6442450944UL,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1120UL};

  ulong outer_data[32] = {
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL,
      0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL, 0x5C5C5C5C5C5C5C5CUL};

  uchar key_ulongs = ((password_len + 7) / 8);
#pragma unroll 4
  for (uchar i = 0; i <= key_ulongs; ++i) {
    inner_data[i] = password[i] ^ 0x3636363636363636UL;
    outer_data[i] = password[i] ^ 0x5C5C5C5C5C5C5C5CUL;
  }
  ulong inner_H[8];
  INIT_SHA512(inner_H);
  sha512_hash_two_blocks_message(inner_data, inner_H);
  ADJUST_DATA(outer_data, inner_H);
  sha512_hash_two_blocks_message(outer_data, T);
  ulong UX[8];
  ulong U[8];

  COPY_EIGHT(U, T);
  ulong inner_J[8];
#pragma nounroll
#pragma loop dependence(enable)

  for (ushort i = 1; i < 2048; ++i) {
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