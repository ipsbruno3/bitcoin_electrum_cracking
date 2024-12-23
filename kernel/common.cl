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
  // Lembra-se que ele corta o último caractere!
  output[offset - 1] = '\0';
}
