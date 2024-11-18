

#define uint64 ulong
#define uint32 unsigned int
#define uint64_t ulong
#define uint8_t unsigned char
#define uint32_t int
#define uint16 unsigned short
#define uint8 unsigned char

#define MAX_WORD_LENGTH 8
#define NUM_WORDS 2048
#define TOTAL_CHECKSUM_MATCHES 128

#define CHECKSUM_BITS 16
#define SEED_SIZE 12

#define rotate_right(x, n) ((x >> n) | (x << (64 - n)))
#define ROTR64_SHA512(x, n) (((x) >> (n)) | ((x) << (64 - (n))))
int strlen(char *s)
{
  int l;
  for (l = 0; s[l] != '\0'; l++)
  {
    continue;
  }
  return l;
}

void memcpy(void *dest,  void *src, int  n) {
    uchar *d = (uchar *)dest;
    const uchar *s = (const uchar *)src;
    for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
    }
}


void memset(void *s, int c, int n) {
    uchar *p = (uchar *)s;
    uchar value = (uchar)c;
    for (int i = 0; i < n; i++) {
        p[i] = value;
    }
}



void hash_to_hex_string_retn(ulong *hash, char *output) {
    const char hex[] = "0123456789abcdef"; 
    for (int i = 0; i < 8; i++) for (int j = 56; j >= 0; j -= 8) { unsigned char b = (hash[i] >> j) & 0xFF; *output++ = hex[b >> 4]; *output++ = hex[b & 0x0F]; } 
    *output = '\0';
}
void ulong_array_to_char(ulong *values, int len, char *output) {
    const char hex[] = "0123456789abcdef";
    for (int i = 0; i < len; i++) {
        for (int j = 15; j >= 0; j--, values[i] >>= 4) {
            output[i * 16 + j] = hex[values[i] & 0xF];
        }
    }
}


void uchar_to_ulong(const uchar *input, uint input_len, ulong *output, uint *output_len) {
    uint ulong_count = (input_len + 7) / 8; // Número de ulongs necessários
    *output_len = ulong_count;

    for (uint i = 0; i < ulong_count; i++) {
        ulong temp = 0;
        for (uint j = 0; j < 8; j++) {
            uint index = i * 8 + j;
            if (index < input_len) {
                temp |= ((ulong)input[index] << (56 - j * 8));
            }
        }
        output[i] = temp;
    }
}

