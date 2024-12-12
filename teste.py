from mnemonic import Mnemonic

mnemo = Mnemonic("english")
FIXED_WORDS = "squirrel civil denial manage host wire abandon abandon abandon abandon abandon".split()


def words_to_indices(words):
    """Converte palavras para índices no wordlist BIP-39."""
    return [mnemo.wordlist.index(word) for word in words]


def indices_to_words(indices):
    """Converte índices de volta para palavras no wordlist BIP-39."""
    return [mnemo.wordlist[index] for index in indices]


def seed_to_uint64_pair(indices):
    """Converte os índices em dois valores uint64: high e low."""
    binary_string = ''.join(f"{index:011b}" for index in indices)[:-4]  # Remove os últimos 4 bits (checksum)
    # Certifica que a string tem no mínimo 64 bits para high e low
    binary_string = binary_string.ljust(128, '0')
    high = int(binary_string[:64], 2)
    low = int(binary_string[64:], 2)
    return high, low


def uint64_pair_to_seed(high, low, num_words=12):
    """Converte uint64 (high, low) de volta para os índices."""
    # Reconstroi a string binária de 128 bits (ou menos se low for 0)
    binary_string = f"{high:064b}" + f"{low:064b}"
    indices = [int(binary_string[i:i+11], 2) for i in range(0, num_words * 11, 11)]
    return indices


# Teste
print("=== Conversão de Palavras para uint64 ===")
indices = words_to_indices(FIXED_WORDS)
print(f"Índices: {indices}")

high, low = seed_to_uint64_pair(indices)
print(f"High: {high}, Low: {low}")

print("\n=== Conversão de uint64 para Seed ===")
reconstructed_indices = uint64_pair_to_seed(high, low, len(FIXED_WORDS))
reconstructed_words = indices_to_words(reconstructed_indices)

print(f"Índices Reconvertidos: {reconstructed_indices}")
print(f"Palavras Reconvertidas: {' '.join(reconstructed_words)}")
