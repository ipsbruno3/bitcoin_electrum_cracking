
#include "../kernel/sha256.h"

uchar sha256_from_byte(ulong max, ulong min) {

  uint w[64] = {0};
  uint a, b, c, d, e, f, g, h, temp1, temp2;

  w[0] = (max >> 32) & 0xFFFFFFFF;
  w[1] = max & 0xFFFFFFFF;
  w[2] = (min >> 32) & 0xFFFFFFFF;
  w[3] = min & 0xFFFFFFFF;
  w[4] = 0x80000000;
  w[15] = 128;

#pragma unroll
  for (int i = 16; i < 64; ++i) {
    w[i] = w[i - 16] +
           ((ROTR_256(w[i - 15], 7)) ^ (ROTR_256(w[i - 15], 18)) ^
            (w[i - 15] >> 3)) +
           w[i - 7] +
           ((ROTR_256(w[i - 2], 17)) ^ (ROTR_256(w[i - 2], 19)) ^
            (w[i - 2] >> 10));
  }

  a = H0_256;
  b = H1_256;
  c = H2_256;
  d = H3_256;
  e = H4_256;
  f = H5_256;
  g = H6_256;
  h = H7_256;

#pragma unroll
  for (int i = 0; i < 63; ++i) {

    temp1 = h + ((ROTR_256(e, 6)) ^ (ROTR_256(e, 11)) ^ (ROTR_256(e, 25))) +
            ((e & f) ^ ((~e) & g)) + K_256[i] + w[i];
    temp2 = ((ROTR_256(a, 2)) ^ (ROTR_256(a, 13)) ^ (ROTR_256(a, 22))) +
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

  temp1 = (h + ((ROTR_256(e, 6)) ^ (ROTR_256(e, 11)) ^ (ROTR_256(e, 25))) +
           ((e & f) ^ ((~e) & g)) + K_256[63] + w[63]);
  temp2 = (((ROTR_256(a, 2)) ^ (ROTR_256(a, 13)) ^ (ROTR_256(a, 22))) +
           ((a & b) ^ (a & c) ^ (b & c)));

  a = temp1 + temp2;

  return (uchar)(((H0_256 + a) >> 24) & 0xFF);
}

#undef H0
#undef H1
#undef H2
#undef H3
#undef H4
#undef H5
#undef H6
#undef H7
