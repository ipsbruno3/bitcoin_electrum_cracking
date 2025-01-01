

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
                ((ulong)input[baseIndex + 6] 
                << 8UL) |
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


void *memcpy(void *dest, const void *src, size_t n) {
  char *d = (char *)dest;
  const char *s = (char *)src;

  if (n < 5) {
    if (n == 0)
      return dest;
    d[0] = s[0];
    d[n - 1] = s[n - 1];
    if (n <= 2)
      return dest;
    d[1] = s[1];
    d[2] = s[2];
    return dest;
  }

  if (n <= 16) {
    if (n >= 8) {
      const char *first_s = s;
      const char *last_s = s + n - 8;
      char *first_d = d;
      char *last_d = d + n - 8;
      *((ulong *)first_d) = *((ulong *)first_s);
      *((ulong *)last_d) = *((ulong *)last_s);
      return dest;
    }

    const char *first_s = s;
    const char *last_s = s + n - 4;
    char *first_d = d;
    char *last_d = d + n - 4;
    *((uint *)first_d) = *((uint *)first_s);
    *((uint *)last_d) = *((uint *)last_s);
    return dest;
  }

  if (n <= 32) {
    const char *first_s = s;
    const char *last_s = s + n - 16;
    char *first_d = d;
    char *last_d = d + n - 16;

    *((long16 *)first_d) = *((long16 *)first_s);
    *((long16 *)last_d) = *((long16 *)last_s);
    return dest;
  }

  const char *last_word_s = s + n - 32;
  char *last_word_d = d + n - 32;

  // Stamp the 32-byte chunks.
  do {
    *((long16 *)d) = *((long16 *)s);
    d += 32;
    s += 32;
  } while (d < last_word_d);

  // Stamp the last unaligned 32 bytes of the buffer.
  *((long16 *)last_word_d) = *((long16 *)last_word_s);
  return dest;
}