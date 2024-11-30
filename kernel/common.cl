#define MAX_WORD_LENGTH 8
#define NUM_WORDS 2048
#define TOTAL_CHECKSUM_MATCHES 128
#define rotate_right(x, n) ((x >> n) | (x << (64 - n)))
#define ROTR64_SHA512(x, n) (((x) >> (n)) | ((x) << (64 - (n))))

#define H0_SHA512 0x6a09e667f3bcc908ULL
#define H1_SHA512 0xbb67ae8584caa73bULL
#define H2_SHA512 0x3c6ef372fe94f82bULL
#define H3_SHA512 0xa54ff53a5f1d36f1ULL
#define H4_SHA512 0x510e527fade682d1ULL
#define H5_SHA512 0x9b05688c2b3e6c1fULL
#define H6_SHA512 0x1f83d9abfb41bd6bULL
#define H7_SHA512 0x5be0cd19137e2179ULL

#define DEBUG_ARRAY(name, array, len)                                          \
  do {                                                                         \
    printf("%s: ", name);                                                      \
    for (uint i = 0; i < (len); i++) {                                         \
      printf("%016lx ", (array)[i]);                                           \
    }                                                                          \
    printf("\n");                                                              \
  } while (0)

uint strlen(uchar *s) {
  uint l;
  for (l = 0; s[l] != '\0'; l++) {
    continue;
  }
  return l;
}

void memcpy(void *dest, void *src, int n) {
  uchar *d = (uchar *)dest;
  const uchar *s = (const uchar *)src;
  for (size_t i = 0; i < n; i++) {
    d[i] = s[i];
  }
}

void ulong_to_uchar(ulong *input, uint input_len, uchar *output) {
  for (uint i = 0; i < input_len; i++) {
    for (uint j = 0; j < 8; j++) {
      output[i * 8 + j] = (uchar)((input[i] >> (56 - j * 8)) & 0xFF);
    }
  }
}

void memset(void *s, int c, int n) {
  uchar *p = (uchar *)s;
  uchar value = (uchar)c;
  for (int i = 0; i < n; i++) {
    p[i] = value;
  }
}

void hash_to_hex_string_retn(ulong *hash, uchar *output) {
  const uchar hex[] = "0123456789abcdef";
  for (int i = 0; i < 8; i++)
    for (int j = 56; j >= 0; j -= 8) {
      uchar b = (hash[i] >> j) & 0xFF;
      *output++ = hex[b >> 4];
      *output++ = hex[b & 0x0F];
    }
  *output = '\0';
}

void ulong_array_to_char(const ulong *input, uint input_len, uchar *output) {
  const uchar hex[] = "0123456789abcdef";
  for (uint i = 0; i < input_len; i++) {
    for (uint j = 0; j < 8; j++) {
      uchar byte = (input[i] >> (56 - j * 8)) & 0xFF;
      *output++ = hex[byte >> 4];
      *output++ = hex[byte & 0x0F];
    }
  }
  *output = '\0'; // Adiciona o terminador de string
}

void uchar_to_ulong(uchar *input, int input_len, ulong *output) {
  int ulong_count = (input_len + 7) / 8; // Número de ulong necessários

  for (int i = 0; i < ulong_count; i++) {
    output[i] = 0; // Inicializa o ulong com 0
    for (int j = 0; j < 8; j++) {
      int index = i * 8 + j;
      if (index < input_len) {
        output[i] |= ((ulong)input[index])
                     << (56 - j * 8); // Preenche byte a byte
      }
    }
  }

  // Adiciona padding no último bloco, incluindo o byte \x80
  if (input_len % 8 != 0) {
    int last_block_index = (input_len - 1) / 8;
    output[last_block_index] |= (ulong)0x80 << (56 - ((input_len % 8) * 8));
  }
}
