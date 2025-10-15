// ===== n (ordem do grupo) em 4x64 big-endian =====
#define N0 ((ulong)0xFFFFFFFFFFFFFFFFUL)
#define N1 ((ulong)0xFFFFFFFFFFFFFFFEUL)
#define N2 ((ulong)0xBAAEDCE6AF48A03BUL)
#define N3 ((ulong)0xBFD25E8CD0364141UL)

#define PVT __private

/* ===== add/sub e mod n em 256-bit (4x64 BE) ===== */

inline void add256_be(PVT ulong r[4], const PVT ulong a[4],
                      const PVT ulong b[4], PVT int *carry) {
  ulong c = 0;
  for (int i = 3; i >= 0; --i) {
    ulong s = a[i] + b[i], s2 = s + c;
    r[i] = s2;
    c = (s < b[i]) | (s2 < s);
  }
  *carry = (int)c;
}

inline void sub256_be(PVT ulong r[4], const PVT ulong a[4],
                      const PVT ulong b[4]) {
  ulong c = 0;
  for (int i = 3; i >= 0; --i) {
    ulong bi = b[i] + c;
    c = (a[i] < bi);
    r[i] = a[i] - bi;
  }
}

inline int ge_n(const PVT ulong a[4]) {
  if (a[0] != N0)
    return a[0] > N0;
  if (a[1] != N1)
    return a[1] > N1;
  if (a[2] != N2)
    return a[2] > N2;
  return a[3] >= N3;
}

inline void addmod_n(PVT ulong r[4], const PVT ulong a[4],
                     const PVT ulong b[4]) {
  int carry;
  add256_be(r, a, b, &carry);

  if (carry || ge_n(r)) {
    /* NÃO use (ulong[4]){...} aqui. Alguns compiladores tratam isso como
     * genérico. */
    const PVT ulong N_BE[4] = {N0, N1, N2, N3};
    sub256_be(r, r, N_BE);
  }
}

// ===== HMAC-SHA512(key=32B) p/ msg de 37 bytes (5 words) =====
inline void hmac512_ccode_msg37(const ulong c[4], ulong M0, ulong M1, ulong M2,
                                ulong M3, ulong M4top5, ulong Hout[8]) {
  ulong inner[32], outer[32];
  inner[0] = c[0] ^ IPAD;
  inner[1] = c[1] ^ IPAD;
  inner[2] = c[2] ^ IPAD;
  inner[3] = c[3] ^ IPAD;
  outer[0] = c[0] ^ OPAD;
  outer[1] = c[1] ^ OPAD;
  outer[2] = c[2] ^ OPAD;
  outer[3] = c[3] ^ OPAD;
  for (int i = 4; i < 16; i++) {
    inner[i] = IPAD;
    outer[i] = OPAD;
  }

  // inner: (K^ipad)||msg(37)||0x80||zeros||len(1320)
  inner[16] = M0;
  inner[17] = M1;
  inner[18] = M2;
  inner[19] = M3;
  inner[20] = M4top5 | ((ulong)0x80UL << 16);
  for (int i = 21; i < 30; i++)
    inner[i] = 0;
  inner[30] = 0;
  inner[31] = (ulong)1320;
  sha512_hash_two_blocks_message(inner, Hout);

  // outer: (K^opad)||H||0x80||zeros||len(1536)
  outer[16] = Hout[0];
  outer[17] = Hout[1];
  outer[18] = Hout[2];
  outer[19] = Hout[3];
  outer[20] = Hout[4];
  outer[21] = Hout[5];
  outer[22] = Hout[6];
  outer[23] = Hout[7];
  outer[24] = 0x8000000000000000UL;
  for (int i = 25; i < 30; i++)
    outer[i] = 0;
  outer[30] = 0;
  outer[31] = (ulong)1536;
  sha512_hash_two_blocks_message(outer, Hout);
}

// ===== empacote msg 37 bytes =====
inline void pack_hardened37(const ulong k[4], uint i, ulong *M0, ulong *M1,
                            ulong *M2, ulong *M3, ulong *M4t) {
  *M0 = (k[0] >> 8);
  *M1 = ((k[0] & 0xFFUL) << 56) | (k[1] >> 8);
  *M2 = ((k[1] & 0xFFUL) << 56) | (k[2] >> 8);
  *M3 = ((k[2] & 0xFFUL) << 56) | (k[3] >> 8);
  *M4t = ((k[3] & 0xFFUL) << 56) | ((ulong)((i >> 24) & 0xFF) << 48) |
         ((ulong)((i >> 16) & 0xFF) << 40) | ((ulong)((i >> 8) & 0xFF) << 32) |
         ((ulong)(i & 0xFF) << 24);
}

// LE(8×32) -> BE(4×64) para X
inline uint bswap32(uint v) {
  return (v >> 24) | ((v >> 8) & 0xFF00) | ((v << 8) & 0xFF0000) | (v << 24);
}
// LE(8×32) -> BE(4×64) para X (SEM byte swap)
inline void x_le_to_u64be4(const uint x[8], ulong Xbe[4]) {
  Xbe[0] = ((ulong)x[7] << 32) | (ulong)x[6];
  Xbe[1] = ((ulong)x[5] << 32) | (ulong)x[4];
  Xbe[2] = ((ulong)x[3] << 32) | (ulong)x[2];
  Xbe[3] = ((ulong)x[1] << 32) | (ulong)x[0];
}

#define is_even32(Y) (!((Y)[0] & 1)) // Y[0] é o LSW em LE

inline void pack_normal37(const uint Xle[8], const uint Yle[8], uint i,
                          ulong *M0, ulong *M1, ulong *M2, ulong *M3,
                          ulong *M4t) {
  ulong Xbe[4];
  x_le_to_u64be4(Xle, Xbe);
  ulong pfx = (is_even32(Yle) ? 0x02UL : 0x03UL) << 56;
  *M0 = pfx | (Xbe[0] >> 8);
  *M1 = ((Xbe[0] & 0xFFUL) << 56) | (Xbe[1] >> 8);
  *M2 = ((Xbe[1] & 0xFFUL) << 56) | (Xbe[2] >> 8);
  *M3 = ((Xbe[2] & 0xFFUL) << 56) | (Xbe[3] >> 8);
  *M4t = ((Xbe[3] & 0xFFUL) << 56) | ((ulong)((i >> 24) & 0xFF) << 48) |
         ((ulong)((i >> 16) & 0xFF) << 40) | ((ulong)((i >> 8) & 0xFF) << 32) |
         ((ulong)(i & 0xFF) << 24);
}

// 4x64 BE -> 8x32 LE (p/ point_mul_xy)
inline void be64_to_le32_8(const ulong k[4], uint outLE[8]) {
  outLE[0] = (uint)(k[3] & 0xffffffffUL);
  outLE[1] = (uint)(k[3] >> 32);
  outLE[2] = (uint)(k[2] & 0xffffffffUL);
  outLE[3] = (uint)(k[2] >> 32);
  outLE[4] = (uint)(k[1] & 0xffffffffUL);
  outLE[5] = (uint)(k[1] >> 32);
  outLE[6] = (uint)(k[0] & 0xffffffffUL);
  outLE[7] = (uint)(k[0] >> 32);
}
inline void print_xy_be(const uint X[8], const uint Y[8]) {

  printf("X=");
  for (int i = 7; i >= 0; --i)
    printf("%08x", X[i]);
  printf("\n");
  printf("Y=");
  for (int i = 7; i >= 0; --i)
    printf("%08x", Y[i]);
  printf("\n");
  printf("PubC=%02x", ((Y[0] & 1) == 0 ? 0x02 : 0x03));
  for (int i = 7; i >= 0; --i)
    printf("%08x", X[i]);
  printf("\n\n");
}

// ===== Deriva m/0'/0/index e retorna X,Y (8×uint LE) =====
inline int derive_m_0h_0_i_pub(const ulong Iroot[8], uint index, ulong k_out[4],
                               ulong c_out[4], uint X[8], uint Y[8]) {
  // master
  ulong km[4] = {Iroot[0], Iroot[1], Iroot[2], Iroot[3]};
  ulong cm[4] = {Iroot[4], Iroot[5], Iroot[6], Iroot[7]};

  // m/0' (hardened)
  ulong M0, M1, M2, M3, M4t, I[8] = {0};
  pack_hardened37(km, 0x80000000u, &M0, &M1, &M2, &M3, &M4t);
  hmac512_ccode_msg37(cm, M0, M1, M2, M3, M4t, I);
  ulong k0h[4] = {I[0], I[1], I[2], I[3]}, c0h[4] = {I[4], I[5], I[6], I[7]};
  addmod_n(k0h, k0h, km);
  if ((k0h[0] | k0h[1] | k0h[2] | k0h[3]) == 0UL)
    return 0;

  // pub m/0'
  uint k0h_le[8];
  be64_to_le32_8(k0h, k0h_le);
  uint X0h[8], Y0h[8];
  point_mul_xy(X0h, Y0h, k0h_le);
  // m/0'/0 (normal)
  pack_normal37(X0h, Y0h, 0u, &M0, &M1, &M2, &M3, &M4t);
  hmac512_ccode_msg37(c0h, M0, M1, M2, M3, M4t, I);
  ulong k0h_0[4] = {I[0], I[1], I[2], I[3]},
        c0h_0[4] = {I[4], I[5], I[6], I[7]};
  addmod_n(k0h_0, k0h_0, k0h);
  if ((k0h_0[0] | k0h_0[1] | k0h_0[2] | k0h_0[3]) == 0UL)
    return 0;

  // pub m/0'/0
  uint k0h0_le[8];
  be64_to_le32_8(k0h_0, k0h0_le);
  uint Xp[8], Yp[8];
  point_mul_xy(Xp, Yp, k0h0_le);

  // m/0'/0/index (normal)
  pack_normal37(Xp, Yp, index, &M0, &M1, &M2, &M3, &M4t);
  hmac512_ccode_msg37(c0h_0, M0, M1, M2, M3, M4t, I);
  k_out[0] = I[0];
  k_out[1] = I[1];
  k_out[2] = I[2];
  k_out[3] = I[3];
  addmod_n(k_out, k_out, k0h_0);
  if ((k_out[0] | k_out[1] | k_out[2] | k_out[3]) == 0UL)
    return 0;
  c_out[0] = I[4];
  c_out[1] = I[5];
  c_out[2] = I[6];
  c_out[3] = I[7];

  // pub final do filho
  uint k_le[8];
  be64_to_le32_8(k_out, k_le);
  point_mul_xy(X, Y, k_le);

  return 1;
}
