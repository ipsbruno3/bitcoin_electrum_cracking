


#define COPY_EIGHT(a, b)                                                       \
  (a)[0] = (b)[0], (a)[1] = (b)[1], (a)[2] = (b)[2], (a)[3] = (b)[3],          \
  (a)[4] = (b)[4], (a)[5] = (b)[5], (a)[6] = (b)[6], (a)[7] = (b)[7];

#define COPY_EIGHT_XOR(a, b)                                                   \
  (a)[0] ^= (b)[0];                                                            \
  (a)[1] ^= (b)[1];                                                            \
  (a)[2] ^= (b)[2];                                                            \
  (a)[3] ^= (b)[3];                                                            \
  (a)[4] ^= (b)[4];                                                            \
  (a)[5] ^= (b)[5];                                                            \
  (a)[6] ^= (b)[6];                                                            \
  (a)[7] ^= (b)[7];


#define DEBUG_ARRAY(name, array, len)                                          \
  do {                                                                         \
    for (uint i = 0; i < (len); i++) {                                         \
      printf("%s[%d] = 0x%016lxUL\n",name,i, (array)[i]);                                       \
    }                                                                          \
                                                                  \
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
