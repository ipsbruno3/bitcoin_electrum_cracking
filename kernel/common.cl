

#define DEBUG_ARRAY(name, array, len)                                          \
  do {                                                                         \
    for (uint i = 0; i < (len); i++) {                                         \
      printf("0x%016lxUL ", (array)[i]);                                       \
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

inline bool strcmp(uchar *str1, uchar *str2) {
  int i = 0;
  while (str1[i] == str2[i] && str1[i] != '\0') {
    i++;
  }
  return (str1[i] == str2[i]) ? 1 : 0;
}
void uchar_to_ulong2(const char *input, int length, ulong *output, int offset) {
  for (int i = 0; i < length / 8; i++) {
    // Combinar 8 caracteres consecutivos em um ulong
    output[i + offset] = 0;
    for (int j = 0; j < 8; j++) {
      output[i + offset] |= (ulong)(unsigned char)input[i * 8 + j]
                            << (56 - j * 8);
    }
  }
}
inline void uchar_to_ulong(const uchar *input, uint input_len, ulong *output,
                           const uchar offset) {
  const uchar num_ulongs = (input_len + 7) / 8;
  for (uchar i = offset; i < num_ulongs; i++) {
    const uchar baseIndex = i * 8;
    output[i] = ((ulong)input[baseIndex] << 56UL) |
                ((ulong)input[baseIndex + 1] << 48UL) |
                ((ulong)input[baseIndex + 2] << 40UL) |
                ((ulong)input[baseIndex + 3] << 32UL) |
                ((ulong)input[baseIndex + 4] << 24UL) |
                ((ulong)input[baseIndex + 5] << 16UL) |
                ((ulong)input[baseIndex + 6] << 8UL) |
                ((ulong)input[baseIndex + 7]);
  }
}

inline void ulong_array_to_char(const ulong *input, uint input_len,
                                uchar *output) {
  const uchar hex[] = "0123456789abcdef";
  for (uint i = 0; i < input_len; i++) {
    for (uint j = 0; j < 8; j++) {
      uchar byte = (input[i] >> (56 - j * 8)) & 0xFF;
      *output++ = hex[byte >> 4];
      *output++ = hex[byte & 0x0F];
    }
  }
  *output = '\0';
}
void ulong_to_char_buffer(const ulong *ulong_array, int count, uchar *output) {
  int offset = 0;

  for (int i = 0; i < count; i++) {
    for (int j = 0; j < 8; j++) {
      char c = (char)((ulong_array[i] >> ((7 - j) * 8)) & 0xFF);
      if (c != '\0') {
        output[offset++] = c;
      }
    }
  }
  output[offset - 1] = '\0';
}

void memcpy(void *dest, const void *src, size_t n) {
  // Converta os ponteiros para `char *` para copiar byte a byte
  char *d = (char *)dest;
  const char *s = (const char *)src;

  // Copie os bytes
  for (size_t i = 0; i < n; i++) {
    d[i] = s[i];
  }
}
