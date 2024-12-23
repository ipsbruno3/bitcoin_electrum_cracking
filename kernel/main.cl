#include "./kernel/bip39.cl"

void pbkdf2_hmac_sha512_long(ulong *password, uchar password_len, ulong *T);
uchar sha256_from_byte(ulong max, ulong min);

#define CONCAT_BLOCK(b)                                                        \
  {                                                                            \
    ulong val = 0UL;                                                           \
    for (int i = 0; i < 8; i++) {                                              \
      val |= ((ulong)seedString[(b) * 8 + i]) << (8 * i);                      \
    }                                                                          \
    blocks[(b)] = val;                                                         \
  }

#define CONCAT_WORD(w)                                                         \
  {                                                                            \
    int wIdx = seedNum[(w)];                                                   \
    for (int i = 0; i < 9; ++i) {                                              \
      seedString[offset + i] = wordsString[wIdx][i];                           \
    }                                                                          \
    offset += wordsLen[wIdx] + 1;                                              \
  }

__kernel void verifySeed(__global ulong *output, ulong O, ulong H, ulong L,
                         ulong V) {
  ulong idx = get_global_id(0);

  ulong memHigh = H;
  ulong memLow = L + (O + idx) * V;
  ulong finalMem = memLow + V;

  uint seedNum[12] = {0};
  seedNum[0] = (memHigh & (2047UL << 53UL)) >> 53UL;
  seedNum[1] = (memHigh & (2047UL << 42UL)) >> 42UL;
  seedNum[2] = (memHigh & (2047UL << 31UL)) >> 31UL;
  seedNum[3] = (memHigh & (2047UL << 20UL)) >> 20UL;
  seedNum[4] = (memHigh & (2047UL << 9UL)) >> 9UL;
  seedNum[5] = (memHigh << 55UL) >> 53UL | ((memLow & (3UL << 62UL)) >> 62UL);
  seedNum[6] = (memLow & (2047UL << 51UL)) >> 51UL;

  uint offset = 0;
  uchar seedString[128] = {0};
  ulong blocks[16] = {0};

  CONCAT_WORD(0);
  CONCAT_WORD(1);
  CONCAT_WORD(2);
  CONCAT_WORD(3);
  CONCAT_WORD(4);
  CONCAT_WORD(5);
  CONCAT_WORD(6);
  uint oldOffset = offset;
  uint fixBlock = offset / 8;
  for (int i = 0; i < fixBlock; i++) {
    CONCAT_BLOCK(i);
  }

  for (; memLow < finalMem; memLow++) {
    uchar checksum = sha256_from_byte(memHigh, memLow) >> 4UL;
    seedNum[7] = (memLow & (2047UL << 40UL)) >> 40UL;
    seedNum[8] = (memLow & (2047UL << 29UL)) >> 29UL;
    seedNum[9] = (memLow & (2047UL << 18UL)) >> 18UL;
    seedNum[10] = (memLow & (2047UL << 7UL)) >> 7UL;
    seedNum[11] = ((memLow << 57UL) >> 53UL) | checksum;

    CONCAT_WORD(7);
    CONCAT_WORD(8);
    CONCAT_WORD(9);
    CONCAT_WORD(10);
    CONCAT_WORD(11);

    seedString[offset - 1] = '\0';

    for (int i = fixBlock; i < 16; i++) {
      CONCAT_BLOCK(i);
    }
    offset = oldOffset;

    ulong pbkdf2[8] = {0};
    pbkdf2_hmac_sha512_long(blocks, offset - 1, pbkdf2);
    if (memLow % 100000 == 0) {
      printf("\nSeed: |%s|%lu|\n", seedString, pbkdf2[0]);
    }
  }
}
