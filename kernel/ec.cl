// OpenCL C (1.2+). Rotinas de campo e ECC para secp256k1, otimizadas e corrigidas.
// Sem comentários sarcásticos aqui dentro, só bits.

// ===== Constantes da curva =====
#define SECP256K1_B 7

#define SECP256K1_P0 0xfffffc2f
#define SECP256K1_P1 0xfffffffe
#define SECP256K1_P2 0xffffffff
#define SECP256K1_P3 0xffffffff
#define SECP256K1_P4 0xffffffff
#define SECP256K1_P5 0xffffffff
#define SECP256K1_P6 0xffffffff
#define SECP256K1_P7 0xffffffff

#define SECPK256K_VALUES \
  SECP256K1_P0, SECP256K1_P1, SECP256K1_P2, SECP256K1_P3, \
  SECP256K1_P4, SECP256K1_P5, SECP256K1_P6, SECP256K1_P7

// Tabela (w=4) pré-computada para G (X | Y), 12 pontos * (8 + 8) words de 32 bits = 96.
__constant uint secpk256PreComputed[96] = {
    0x16f81798, 0x59f2815b, 0x2dce28d9, 0x029bfcdb, 0xce870b07, 0x55a06295,
    0xf9dcbbac, 0x79be667e, 0xfb10d4b8, 0x9c47d08f, 0xa6855419, 0xfd17b448,
    0x0e1108a8, 0x5da4fbfc, 0x26a3c465, 0x483ada77, 0x04ef2777, 0x63b82f6f,
    0x597aabe6, 0x02e84bb7, 0xf1eef757, 0xa25b0403, 0xd95c3b9a, 0xb7c52588,
    0xbce036f9, 0x8601f113, 0x836f99b0, 0xb531c845, 0xf89d5229, 0x49344f85,
    0x9258c310, 0xf9308a01, 0x84b8e672, 0x6cb9fd75, 0x34c2231b, 0x6500a999,
    0x2a37f356, 0x0fe337e6, 0x632de814, 0x388f7b0f, 0x7b4715bd, 0x93460289,
    0xcb3ddce4, 0x9aff5666, 0xd5c80ca9, 0xf01cc819, 0x9cd217eb, 0xc77084f0,
    0xb240efe4, 0xcba8d569, 0xdc619ab7, 0xe88b84bd, 0x0a5c5128, 0x55b4a725,
    0x1a072093, 0x2f8bde4d, 0xa6ac62d6, 0xdca87d3a, 0xab0d6840, 0xf788271b,
    0xa6c9c426, 0xd4dba9dd, 0x36e5e3d6, 0xd8ac2226, 0x59539959, 0x235782c4,
    0x54f297bf, 0x0877d8e4, 0x59363bd9, 0x2b245622, 0xc91a1c29, 0x2753ddd9,
    0xcac4f9bc, 0xe92bdded, 0x0330e39c, 0x3d419b7e, 0xf2ea7a0e, 0xa398f365,
    0x6e5db4ea, 0x5cbdf064, 0x087264da, 0xa5082628, 0x13fde7b5, 0xa813d0b8,
    0x861a54db, 0xa3178d6d, 0xba255960, 0x6aebca40, 0xf78d9755, 0x5af7d9d6,
    0xec02184a, 0x57ec2f47, 0x79e5ab24, 0x5ce87292, 0x45daa69f, 0x951435bf
};

#define SECP256K1_PRE_COMPUTED_XY_SIZE 96
#define SECP256K1_NAF_SIZE 33

// ===== Macros utilitárias =====
#define is_zero(n) \
  (!n[8] && !n[7] && !n[6] && !n[5] && !n[4] && !n[3] && !n[2] && !n[1] && !n[0])

#define shift_first(aElem, lastValue) do { \
  (aElem)[0] = ((aElem)[0] >> 1) | ((aElem)[1] << 31); \
  (aElem)[1] = ((aElem)[1] >> 1) | ((aElem)[2] << 31); \
  (aElem)[2] = ((aElem)[2] >> 1) | ((aElem)[3] << 31); \
  (aElem)[3] = ((aElem)[3] >> 1) | ((aElem)[4] << 31); \
  (aElem)[4] = ((aElem)[4] >> 1) | ((aElem)[5] << 31); \
  (aElem)[5] = ((aElem)[5] >> 1) | ((aElem)[6] << 31); \
  (aElem)[6] = ((aElem)[6] >> 1) | ((aElem)[7] << 31); \
  (aElem)[7] = (lastValue); \
} while(0)

#define copy_eight(a, b) do { \
  (a)[0]=(b)[0]; (a)[1]=(b)[1]; (a)[2]=(b)[2]; (a)[3]=(b)[3]; \
  (a)[4]=(b)[4]; (a)[5]=(b)[5]; (a)[6]=(b)[6]; (a)[7]=(b)[7]; \
} while(0)

#define is_even(x) (!((x)[0] & 1u))

// ===== Comparações =====
static inline bool arrays_equal(const uint *a, const uint *b) {
  #pragma unroll
  for (int i = 0; i < 8; i++) if (a[i] != b[i]) return false;
  return true;
}

static inline bool is_greater(const uint *a, const uint *b) {
  for (int i = 7; i >= 0; i--) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

static inline bool is_less(const uint *a, const uint *b) {
  for (int i = 7; i >= 0; i--) {
    if (a[i] != b[i]) return a[i] < b[i];
  }
  return false;
}

static inline bool ge_p(const uint *r) {
  const uint p[8] = { SECPK256K_VALUES };
  for (int i = 7; i >= 0; --i) {
    if (r[i] > p[i]) return true;
    if (r[i] < p[i]) return false;
  }
  return true; // r == p
}

// ===== Aritmética básica de 256 bits =====
static inline uint add_u256(uint *r, const uint *a, const uint *b) {
  ulong c = 0;
  #pragma unroll
  for (int i = 0; i < 8; ++i) {
    ulong s = (ulong)a[i] + (ulong)b[i] + c;
    r[i] = (uint)s;
    c = s >> 32;
  }
  return (uint)c;
}

static inline uint sub_u256(uint *r, const uint *a, const uint *b) {
  // borrow = (a < b)
  uint borrow = 0;
  #pragma unroll
  for (int i = 0; i < 8; ++i) {
    ulong ai = (ulong)a[i];
    ulong bi = (ulong)b[i] + (ulong)borrow;
    r[i] = (uint)(ai - bi);
    borrow = (ai < bi);
  }
  return borrow;
}

static inline void add_mod(uint *r, const uint *a, const uint *b) {
  uint c = add_u256(r, a, b);
  if (c || ge_p(r)) {
    const uint p[8] = { SECPK256K_VALUES };
    sub_u256(r, r, p);
  }
}

static inline void sub_mod(uint *r, const uint *a, const uint *b) {
  const uint borrow = sub_u256(r, a, b);
  if (borrow) {
    const uint p[8] = { SECPK256K_VALUES };
    add_u256(r, r, p);
  }
}

// ===== Multiplicação e redução mod p (especial para p = 2^256 - 2^32 - 977) =====
// Estratégia: produto de 512 bits t[0..15]; dobre a metade alta H via r += 977*H e r += H<<32.
// Faça duas dobras (última carrega para r8), normalize e subtraia p se necessário.
static inline void mul_mod(uint *r, const uint *a, const uint *b) {
  // produto de 512 bits
  ulong acc[16] = {0UL};
  #pragma unroll
  for (int i = 0; i < 8; ++i) {
    #pragma unroll
    for (int j = 0; j < 8; ++j) {
      acc[i + j] += (ulong)a[i] * (ulong)b[j];
    }
  }

  // Propaga para base 2^32
  uint t[16];
  ulong carry = 0UL;
  #pragma unroll
  for (int i = 0; i < 16; ++i) {
    ulong s = acc[i] + carry;
    t[i] = (uint)s;
    carry = s >> 32;
  }

  // Fold #1: r = L + 977*H + (H << 32)
  ulong R[9] = {0UL}; // 9 para segurar r8
  // L
  #pragma unroll
  for (int i = 0; i < 8; ++i) R[i] = (ulong)t[i];

  // H contribuições
  #pragma unroll
  for (int i = 0; i < 8; ++i) {
    ulong h = (ulong)t[i + 8];
    // 977*h em posição i
    R[i] += h * 977UL;
    // H<<32: adicionar h a R[i+1]
    if (i + 1 < 8) R[i + 1] += h;
    else           R[8]     += h; // cai em r8
  }
  // Propaga carry em R[0..8]
  #pragma unroll
  for (int i = 0; i < 8; ++i) {
    ulong s = R[i];
    r[i] = (uint)s;
    R[i + 1] += s >> 32;
  }
  ulong r8 = R[8]; // pode ser >0

  // Fold #2: se r8 > 0, dobra novamente (2^256 ≡ 2^32 + 977)
  if (r8) {
    ulong c = r8;
    // r0 += 977*c
    ulong s0 = (ulong)r[0] + 977UL * c;
    r[0] = (uint)s0;
    ulong carry2 = s0 >> 32;

    // r1 += c + carry2
    ulong s1 = (ulong)r[1] + c + carry2;
    r[1] = (uint)s1;
    carry2 = s1 >> 32;

    // propaga carry para r[2..7]
    #pragma unroll
    for (int i = 2; i < 8; ++i) {
      ulong si = (ulong)r[i] + carry2;
      r[i] = (uint)si;
      carry2 = si >> 32;
    }

    // pode sobrar carry2 final; reduza novamente usando a mesma congruência
    while (carry2) {
      // carregar 1 * 2^256 -> 2^32 + 977
      ulong s0b = (ulong)r[0] + 977UL;
      r[0] = (uint)s0b;
      ulong c3 = s0b >> 32;

      ulong s1b = (ulong)r[1] + 1UL + c3;
      r[1] = (uint)s1b;
      c3 = s1b >> 32;

      #pragma unroll
      for (int i = 2; i < 8; ++i) {
        ulong sib = (ulong)r[i] + c3;
        r[i] = (uint)sib;
        c3 = sib >> 32;
      }
      carry2--; // consumiu um "2^256"
    }
  }

  // Normaliza se >= p
  if (ge_p(r)) {
    const uint p[8] = { SECPK256K_VALUES };
    sub_u256(r, r, p);
  }
}

// ===== Inversão modular (algoritmo binário estendido) =====
static inline void shift_and_add(uint *x, uint *y, const uint *p) {
  shift_first(x, x[7] >> 1);
  uint c = 0;
  if (!is_even(y)) {
    c = add_u256(y, y, p);
  }
  shift_first(y, (y[7] >> 1) | (c << 31));
}

static inline void sub_and_shift(uint *x, const uint *y, uint *z, const uint *w,
                                 const uint *p) {
  sub_mod(x, x, y);
  shift_first(x, x[7] >> 1);
  if (is_less(z, w)) add_mod(z, z, p);
  sub_mod(z, z, w);

  if (!is_even(z)) {
    uint c = add_u256(z, z, p);
    shift_first(z, (z[7] >> 1) | (c << 31));
  } else {
    shift_first(z, z[7] >> 1);
  }
}

static inline void inv_mod(uint *a) {
  uint t0[8] = { a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7] };
  const uint p[8] = { SECPK256K_VALUES };
  uint t1[8] = { SECPK256K_VALUES };
  uint t2[8] = { 1,0,0,0,0,0,0,0 };
  uint t3[8] = { 0,0,0,0,0,0,0,0 };

  while (!arrays_equal(t0, t1)) {
    if (is_even(t0)) {
      shift_and_add(t0, t2, p);
    } else if (is_even(t1)) {
      shift_and_add(t1, t3, p);
    } else {
      if (is_greater(t0, t1)) {
        sub_and_shift(t0, t1, t2, t3, p);
      } else {
        sub_and_shift(t1, t0, t3, t2, p);
      }
    }
  }
  copy_eight(a, t2);
}

// ===== Operações de ponto (Jacobiano com z2=1 para add de pré-computado) =====
static inline void point_double(uint *x, uint *y, uint *z) {
  uint t1[8], t2[8], t3[8], t4[8], t5[8], t6[8];

  copy_eight(t3, z);
  copy_eight(t2, y);
  mul_mod(t4, x, x);         // t4 = x^2
  mul_mod(t5, y, y);         // t5 = y^2
  mul_mod(t3, y, z);         // t3 = y*z
  mul_mod(t1, x, t5);        // t1 = x*y^2
  mul_mod(t5, t5, t5);       // t5 = y^4

  // t4 = 3*x^2
  add_mod(t2, t4, t4);
  add_mod(t4, t4, t2);

  // t4 = (3*x^2)/2 mod p
  uint c = 0;
  if (t4[0] & 1u) {
    const uint p[8] = { SECPK256K_VALUES };
    c = add_u256(t4, t4, p);
  }
  shift_first(t4, (t4[7] >> 1) | (c << 31));

  mul_mod(t6, t4, t4);       // t6 = ((3x^2)/2)^2
  add_mod(t2, t1, t1);       // t2 = 2*x*y^2
  sub_mod(t6, t6, t2);       // x' = t6 - 2*t1

  sub_mod(t1, t1, t6);       // t1 = t1 - x'
  mul_mod(t4, t4, t1);       // t4 = slope * (t1)
  sub_mod(t1, t4, t5);       // y' = t4 - y^4

  copy_eight(x, t6);
  copy_eight(y, t1);
  copy_eight(z, t3);
}

static inline void point_add(uint *x1, uint *y1, uint *z1,
                             __constant uint *x2,
                             __constant uint *y2) { // z2 = 1
  uint t1[8], t2[8], t3[8], t4[8], t5[8], t6[8], t7[8], t8[8], t9[8];

  copy_eight(t1, x1);
  copy_eight(t2, y1);
  copy_eight(t3, z1);
  copy_eight(t4, x2);
  copy_eight(t5, y2);

  mul_mod(t6, t3, t3);   // t6 = z1^2
  mul_mod(t7, t6, t3);   // t7 = z1^3
  mul_mod(t6, t6, t4);   // t6 = x2*z1^2
  mul_mod(t7, t7, t5);   // t7 = y2*z1^3

  sub_mod(t6, t6, t1);   // t6 = U2 - X1
  sub_mod(t7, t7, t2);   // t7 = S2 - Y1

  mul_mod(t8, t3, t6);   // t8 = z1*H
  mul_mod(t4, t6, t6);   // t4 = H^2
  mul_mod(t9, t4, t6);   // t9 = H^3
  mul_mod(t4, t4, t1);   // t4 = X1*H^2

  // t6 = 2*t4 (com correção modular inline rápida)
  t6[7] = (t4[7] << 1) | (t4[6] >> 31);
  t6[6] = (t4[6] << 1) | (t4[5] >> 31);
  t6[5] = (t4[5] << 1) | (t4[4] >> 31);
  t6[4] = (t4[4] << 1) | (t4[3] >> 31);
  t6[3] = (t4[3] << 1) | (t4[2] >> 31);
  t6[2] = (t4[2] << 1) | (t4[1] >> 31);
  t6[1] = (t4[1] << 1) | (t4[0] >> 31);
  t6[0] = (t4[0] << 1);

  if (t4[7] & 0x80000000u) {
    // adiciona (2^32 + 977) pela congruência do primo
    uint a[8] = {0x000003d1, 1, 0, 0, 0, 0, 0, 0};
    add_u256(t6, t6, a);
  }

  mul_mod(t5, t7, t7);   // t5 = r^2
  sub_mod(t5, t5, t6);   // t5 = r^2 - 2*X1*H^2
  sub_mod(t5, t5, t9);   // X3 = t5 - H^3

  sub_mod(t4, t4, t5);   // t4 = X1*H^2 - X3
  mul_mod(t4, t4, t7);   // t4 = r*(...)
  mul_mod(t9, t9, t2);   // t9 = Y1*H^3
  sub_mod(t9, t4, t9);   // Y3 = r*(X1*H^2 - X3) - Y1*H^3

  copy_eight(x1, t5);
  copy_eight(y1, t9);
  copy_eight(z1, t8);
}

// ===== NAF (window=4) e multiplicação escalar =====
static inline uint msb_point(uint *n) {
  uint msb = 256;
  for (int i = 8; i >= 0; --i) {
    if (n[i]) {
      // OpenCL: clz é o builtin
      msb = (uint)(i * 32 + 31 - clz(n[i]));
      break;
    }
  }
  return msb;
}

static inline int convert_to_window_naf(uint *naf, const uint *k) {
  int loop_start = 0;
  // n[0] é carry/alta; k vem em LE32 [k0..k7]
  uint n[9] = {0, k[7], k[6], k[5], k[4], k[3], k[2], k[1], k[0]};

  uint msb = msb_point(n);

  for (uint i = 0; i <= msb; ++i) {
    if (n[8] & 1u) {
      int diff = (int)(n[8] & 0x0fu);
      int val  = diff;

      if (diff >= 0x08) {
        diff -= 0x10;         // torna negativo
        val   = 0x11 - val;   // codificação impar
      }

      naf[i >> 3] |= (uint)val << ((i & 7u) << 2);

      uint t = n[8];
      n[8] = (uint)((int)n[8] - diff);

      // propaga o ajuste em n[0..8]
      uint idx = 8; // corrigido: não sombreia nome "k"
      while (idx > 0 && ((diff > 0 && n[idx] > t) || (diff < 0 && t > n[idx]))) {
        --idx;
        t = n[idx];
        n[idx] += (diff > 0) ? (uint)-1 : (uint)1;
      }

      loop_start = (int)i;
    }

    // shift à direita de 1 bit em n[0..8]
    for (int j = 8; j > 0; --j) {
      n[j] = (n[j] >> 1) | (n[j - 1] << 31);
    }
    n[0] >>= 1;

    if (is_zero(n)) break;
  }

  return loop_start;
}

static inline void point_mul_xy(uint *x1, uint *y1, const uint *k) {
  uint naf[SECP256K1_NAF_SIZE] = {0};
  int loop_start = convert_to_window_naf(naf, k);

  const uint m0  = (naf[loop_start >> 3] >> ((loop_start & 7) << 2)) & 0x0fu;
  const uint odd = m0 & 1u;

  const uint x_pos0 = ((m0 - 1u + odd) >> 1) * 24u;
  const uint y_pos0 = odd ? (x_pos0 + 8u) : (x_pos0 + 16u);

  copy_eight(x1, secpk256PreComputed + x_pos0);
  copy_eight(y1, secpk256PreComputed + y_pos0);

  uint z1[8] = {1,0,0,0,0,0,0,0};

  for (int pos = loop_start - 1; pos >= 0; --pos) {
    point_double(x1, y1, z1);
    const uint m = (naf[pos >> 3] >> ((pos & 7) << 2)) & 0x0fu;
    if (m) {
      const uint oddm = m & 1u;
      const uint x_pos = ((m - 1u + oddm) >> 1) * 24u;
      const uint y_pos = oddm ? (x_pos + 8u) : (x_pos + 16u);
      point_add(x1, y1, z1, secpk256PreComputed + x_pos, secpk256PreComputed + y_pos);
    }
  }

  // volta para afim: (x/z^2, y/z^3)
  inv_mod(z1);
  uint z2[8];
  mul_mod(z2, z1, z1);
  mul_mod(x1, x1, z2);
  mul_mod(z1, z2, z1);
  mul_mod(y1, y1, z1);
}

