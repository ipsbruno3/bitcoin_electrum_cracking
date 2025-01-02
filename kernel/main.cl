#include "kernel/bip39.cl"
#include "kernel/ec.cl"

inline void prepareSeedString(uint *seedNum, uchar *seedString, uchar *offset) {
#pragma unroll 12
  for (int i = 0, y; i < 12; i++) {
    y = seedNum[i];
#pragma unroll 9
    for (int j = 0; j < 9; j++) {
      seedString[*offset + j] = wordsString[y][j];
    }
    *offset += wordsLen[y] + 1;
  }
  seedString[*offset - 1] = '\0';
}

inline void prepareSeedNumber(uint *seedNum, ulong memHigh, ulong memLow) {

  uchar checksum = sha256_from_byte(memHigh, memLow) >> 4UL;
  seedNum[0] = (memHigh & (2047UL << 53UL)) >> 53UL,
  seedNum[1] = (memHigh & (2047UL << 42UL)) >> 42UL,
  seedNum[2] = (memHigh & (2047UL << 31UL)) >> 31UL,
  seedNum[3] = (memHigh & (2047UL << 20UL)) >> 20UL,
  seedNum[4] = (memHigh & (2047UL << 9UL)) >> 9UL,
  seedNum[5] = (memHigh << 55UL) >> 53UL | ((memLow & (3UL << 62UL)) >> 62UL),
  seedNum[6] = (memLow & (2047UL << 51UL)) >> 51UL,
  seedNum[7] = (memLow & (2047UL << 40UL)) >> 40UL,
  seedNum[8] = (memLow & (2047UL << 29UL)) >> 29UL,
  seedNum[9] = (memLow & (2047UL << 18UL)) >> 18UL,
  seedNum[10] = (memLow & (2047UL << 7UL)) >> 7UL,
  seedNum[11] = (memLow << 57UL) >> 53UL | checksum;
}

__kernel void verify(__global ulong *L, __global ulong *H,
                     __global ulong *output) {
  int gid = get_global_id(0);

  ulong memHigh = H[0];
  ulong firstMem = L[0];
  ulong memLow = firstMem + gid;
  ulong mnemonicLong[16] = {0}, pbkdLong[10] = {0};
  uchar mnemonicString[128] = {0};
  uchar offset = 0;
  uint seedNum[12] = {0};
  __local ulong arrayLocal[128];
  prepareSeedNumber(seedNum, memHigh, memLow);
  prepareSeedString(seedNum, mnemonicString, &offset);
  uchar_to_ulong(mnemonicString, offset - 1, mnemonicLong, 0);
  pbkdf2_hmac_sha512_long(mnemonicLong, offset - 1, pbkdLong);
  seedNum[0] = pbkdLong[0];
  seedNum[1] = pbkdLong[1];
  seedNum[2] = pbkdLong[2];
  seedNum[3] = pbkdLong[3];
  ulong index = memLow - firstMem;
  ulong x[8];
  ulong y[6];
  point_mul_xy(x, y, seedNum);
  if (index % 10000000 == 0) {
    printf("%s| "
           "PEO:%016llx%016llx%016llx%016llx%016llx%016llx%016llx%016llx%"
           "016llx | W:%016llx | X:%016llx | T:%016llx | U:%016llx | V:%016llx "
           "| Y:%016llx |\n",
           mnemonicString, pbkdLong[0], pbkdLong[1], pbkdLong[2], pbkdLong[3],
           pbkdLong[4], pbkdLong[5], pbkdLong[6], pbkdLong[7], x[0], x[1], x[2],
           x[3], y[0], y[1], y[2]);
  }

  output[index] = pbkdLong[0];
  output[index + 1] = pbkdLong[1];
  output[index + 2] = pbkdLong[2];
  output[index + 3] = pbkdLong[3];
  output[index + 4] = pbkdLong[4];
  output[index + 5] = pbkdLong[5];
  output[index + 6] = pbkdLong[6];
  output[index + 7] = pbkdLong[7];
  output[index + 8] = memLow;
  output[index + 9] = memHigh;
}

__kernel void pbkdf2_hmac_sha512_test(__global uchar *py,
                                      __global uchar *input) {
  /*
    ulong mnemonic_long[32];

    ulong aa[8];
    uchar result[128];
    uchar_to_ulong(input, strlen(input), mnemonic_long, 0);
    pbkdf2_hmac_sha512_long(mnemonic_long, strlen(input), aa);
    ulong_array_to_char(aa, 8, result);

    if (strcmp(result, py)) {
      printf("\nIguais");
    } else {
      printf("\nDiferentes: ");
      printf("Veio de la: %s %s %s", input, result, py);
    }*/
}