
/*
 *   HMAC-SHA-512
 *    A streamlined implementation of the HMAC-SHA-512 algorithm using ulongs.
 *    Minimizes memory usage and reduces instruction count to boost performance.
 *    Works only with 6x4 bytes keys
 *       github.com/ipsbruno
 */

#define IPAD 0x3636363636363636UL
#define OPAD 0x5c5c5c5c5c5c5c5cUL

#define BITCOIN_SEED 0x426974636f696e20UL, 0x7365656400000000UL, 0, 0
#define BITCOIN_SEED_IPAD 0x745f4255595f5816UL, 0x4553535236363636UL
#define BITCOIN_SEED_OPAD 0x1e35283f3335327cUL, 0x2f3939385c5c5c5cUL

#define REPEAT_2(x) x, x
#define REPEAT_4(x) REPEAT_2(x), REPEAT_2(x)
#define REPEAT_5(x) REPEAT_4(x), x
#define REPEAT_6(x) REPEAT_4(x), REPEAT_2(x)
#define REPEAT_7(x) REPEAT_4(x), REPEAT_2(x), x
#define REPEAT_8(x) REPEAT_4(x), REPEAT_4(x)
#define REPEAT_16(x) REPEAT_8(x), REPEAT_8(x)
#define SHOW_ARR(x) x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]

void hmac_sha512_32bytes(ulong *key, ulong *message, ulong *H) {
  ulong inner[32] = {key[0] ^ IPAD,     key[1] ^ IPAD,
                     key[2] ^ IPAD,     key[3] ^ IPAD,
                     REPEAT_6(IPAD),    REPEAT_6(IPAD),
                     SHOW_ARR(message), 0x8000000000000000UL,
                     REPEAT_6(0),       1536};
  ulong outer[32] = {key[0] ^ OPAD,        key[1] ^ OPAD,   key[2] ^ OPAD,
                     key[3] ^ OPAD,        REPEAT_16(OPAD), REPEAT_4(OPAD),
                     0x8000000000000000UL, REPEAT_6(0),     1536};
  sha512_hash_two_blocks_message(inner, H);
  COPY_EIGHT(outer + 16, H);
  sha512_hash_two_blocks_message(outer, H);
}

void hmac_sha512_bitcoin_seed(ulong *message, ulong *H) {
  ulong key[4] = {BITCOIN_SEED};
  hmac_sha512_32bytes(key, message, H);
}
