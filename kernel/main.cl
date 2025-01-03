#include "kernel/bip39.cl"
#include "kernel/common.cl"
#include "kernel/ec.cl"
#include "kernel/sha256.cl"
#include "kernel/sha512_hmac.cl"

const ulong gInnerData[32] = {0x3636363636363636UL,
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

const ulong gOuterData[32] = {0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x5C5C5C5C5C5C5C5CUL,
                              0x8000000000000000UL,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1536U};

#define prepareSeedString(seedNum, seedString, offset)                         \
  {                                                                            \
    for (int i = 0, y; i < 12; i++) {                                          \
      y = seedNum[i];                                                          \
      for (int j = 0; j < 9; j++) {                                            \
        seedString[offset + j] = wordsString[y][j];                            \
      }                                                                        \
      offset += wordsLen[y] + 1;                                               \
    }                                                                          \
    seedString[offset - 1] = '\0';                                             \
  }

#define ucharLong(input, input_len, output, offset)                            \
  {                                                                            \
    const uchar num_ulongs = (input_len + 7) / 8;                              \
    for (uchar i = offset; i < num_ulongs; i++) {                              \
      const uchar baseIndex = i * 8;                                           \
      output[i] = ((ulong)input[baseIndex] << 56UL) |                          \
                  ((ulong)input[baseIndex + 1] << 48UL) |                      \
                  ((ulong)input[baseIndex + 2] << 40UL) |                      \
                  ((ulong)input[baseIndex + 3] << 32UL) |                      \
                  ((ulong)input[baseIndex + 4] << 24UL) |                      \
                  ((ulong)input[baseIndex + 5] << 16UL) |                      \
                  ((ulong)input[baseIndex + 6] << 8UL) |                       \
                  ((ulong)input[baseIndex + 7]);                               \
    }                                                                          \
    for (uchar i = num_ulongs; i < 16; i++) {                                  \
      output[i] = 0;                                                           \
    }                                                                          \
  }

#define prepareSeedNumber(seedNum, memHigh, memLow)                            \
  seedNum[0] = (memHigh & (2047UL << 53UL)) >> 53UL;                           \
  seedNum[1] = (memHigh & (2047UL << 42UL)) >> 42UL;                           \
  seedNum[2] = (memHigh & (2047UL << 31UL)) >> 31UL;                           \
  seedNum[3] = (memHigh & (2047UL << 20UL)) >> 20UL;                           \
  seedNum[4] = (memHigh & (2047UL << 9UL)) >> 9UL;                             \
  seedNum[5] = (memHigh << 55UL) >> 53UL | ((memLow & (3UL << 62UL)) >> 62UL); \
  seedNum[6] = (memLow & (2047UL << 51UL)) >> 51UL;                            \
  seedNum[7] = (memLow & (2047UL << 40UL)) >> 40UL;                            \
  seedNum[8] = (memLow & (2047UL << 29UL)) >> 29UL;                            \
  seedNum[9] = (memLow & (2047UL << 18UL)) >> 18UL;                            \
  seedNum[10] = (memLow & (2047UL << 7UL)) >> 7UL;                             \
  seedNum[11] =                                                                \
      (memLow << 57UL) >> 53UL | sha256_from_byte(memHigh, memLow) >> 4UL;

uchar zeroString[128] = {0};

__kernel void verify(__global ulong *L, __global ulong *H,
                     __global ulong *output) {
  int gid = get_global_id(0);
  int lid = 0;

  ulong inner_data[32];
  ulong outer_data[32];

  ulong memHigh = H[0];
  ulong firstMem = L[0];
  ulong memLow = firstMem + gid;

  ulong mnemonicLong[16];
  ulong pbkdLong[16];
  uint seedNum[16];
  ulong W[180];
  uchar mnemonicString[128] = {0};

  uint offset = 0;
  prepareSeedNumber(seedNum, memHigh, memLow);
  prepareSeedString(seedNum, mnemonicString, offset);
  ucharLong(mnemonicString, offset - 1, mnemonicLong, 0);

  for (lid = 0; lid < 16; lid++) {
    pbkdLong[lid] = 0;
    inner_data[lid] = mnemonicLong[lid] ^ 0x3636363636363636UL;
    outer_data[lid] = mnemonicLong[lid] ^ 0x5C5C5C5C5C5C5C5CUL;
    outer_data[lid + 16] = gOuterData[lid + 16];
    inner_data[lid + 16] = gInnerData[lid + 16];
  }

  pbkdf2_hmac_sha512_long(inner_data, outer_data, pbkdLong);

  if (gid % 50000 == 0) {
    printf("Group: %d | Seed: \"%s\" | %016lx\n", gid, mnemonicString,
           pbkdLong[0]);
  }

  // if (!lid) {

  // printf("%016lx\n", W17);
  // seedNum[0] = (int)pbkdLong[0];
  // seedNum[1] = (int)pbkdLong[1];
  // seedNum[2] = (int)pbkdLong[2];
  // seedNum[3] = (int)pbkdLong[3];
  ulong index = memLow - firstMem;
  // uint x[8];
  // uint y[6];
  // point_mul_xy(x, y, seedNum);

  // output[index] = pbkdLong[0];
  // output[index + 1] = pbkdLong[1];
  // output[index + 2] = pbkdLong[2];
  // output[index + 3] = pbkdLong[3];
  // output[index + 4] = pbkdLong[4];
  // output[index + 5] = pbkdLong[5];
  // output[index + 6] = pbkdLong[6];
  // output[index + 7] = pbkdLong[7];
  // output[index + 8] = memLow;
  // output[index + 9] = memHigh;
  //}
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
