import numpy as np
import pyopencl as cl
from mnemonic import Mnemonic
import hashlib
import time
import hmac



mnemo = Mnemonic("english")
BATCH_SIZE = 1
FIXED_WORDS = "squirrel civil denial manage host wire abandon abandon abandon abandon abandon".split()
WORKERS = 1


import hashlib
import hmac

def create_inner_pad(key: bytes, salt: bytes, block_size: int = 128) -> bytes:
    # Constantes da máscara
    MASK_INNER = 0x36

    # Tamanho total: bloco + salt + comprimento em bits (16 bytes)
    total_len = block_size + len(salt) + 16

    # Inicializa o bloco com máscara INNER
    inner_pad = bytearray([MASK_INNER] * total_len)

    # XOR da chave com a máscara e substituição no bloco
    for i in range(len(key)):
        inner_pad[i] = key[i] ^ MASK_INNER

    # Adiciona o salt imediatamente após a chave
    salt_start_index = len(key)
    for i in range(len(salt)):
        inner_pad[salt_start_index + i] = salt[i]

    # Preenche os últimos 8 bytes com o comprimento total em bits
    length_in_bits = (len(key) + len(salt)) * 8
    length_bytes = length_in_bits.to_bytes(8, byteorder='big')
    length_start_index = total_len - 8
    for i in range(8):
        inner_pad[length_start_index + i] = length_bytes[i]

    return bytes(inner_pad)


def test_inner_pad():
    # Entrada de teste
    key = b"abandona abandona abandona abandona abandona"
    salt = b"mnemonic\0\0\0\1\x80"

    # Construção do INNER_PAD
    inner_pad = create_inner_pad(key, salt)

    # Impressão em formato hexadecimal
    print("INNER_PAD:")
    print(' '.join(f"{x:02x}" for x in inner_pad))


# Executa o teste
test_inner_pad()



def main():
    try:
        indices = words_to_indices(FIXED_WORDS)
    except ValueError as e:
        print(f"Error ao converter palavras em índices: {e}")
        return
    context, queue = initialize_opencl()
    if context is None or queue is None:
        print("Erro ao inicializar o OpenCL. Verifique sua instalação ou configuração.")
        return
    print("OpenCL inicializado com sucesso.")
    try:
        program = build_program(context, "./kernel/common.cl",  "./kernel/sha512_hmac.cl", "./kernel/sha256.cl", "./kernel/main.cl")
    except Exception as e:
        print(f"Erro ao compilar o programa OpenCL: {e}")
        return
    
    print("Programa OpenCL compilado com sucesso.")
    try:
        run_kernel(program, queue, indices, BATCH_SIZE)
        print("Kernel executado com sucesso.")
    except Exception as e:
        print(f"Erro durante a execução do kernel: {e}")
def load_program_source(filename):
    with open(filename, 'r') as f:
        return f.read()




        
def initialize_opencl():
    try:
        platform = cl.get_platforms()[0]
        device = platform.get_devices()[0]
        context = cl.Context([device])
        queue = cl.CommandQueue(context)
        return context, queue
    except Exception as e:
        print(f"Erro ao inicializar o OpenCL: {e}")
        return None, None





def build_program(context, *filenames):
    source_code = ""
    for filename in filenames:
        source_code += load_program_source(filename) + "\n\n\n";
    return cl.Program(context, source_code).build()





def words_to_indices(words):
    indices = []
    for word in words:
        if word in mnemo.wordlist:
            indices.append(mnemo.wordlist.index(word))
    return np.array(indices, dtype=np.int32)





def calculate_checksum(entropy_bytes):
    return hashlib.sha256(entropy_bytes).digest()[0]





def get_binary_string(mnemonic_indices):
    mnemonic_indices = words_to_indices(mnemonic_indices)
    binary_string = ''.join(f"{index:011b}" for index in mnemonic_indices)
    return binary_string





def mnemonic_to_uint64_pair(mnemonic_indices):
    binary_string = get_binary_string(mnemonic_indices)[:-4]
    return binary_string_to_uint64(binary_string)





def binary_string_to_uint64(binary_string):
    high = int(binary_string[:64], 2)
    low = int(binary_string[64:], 2)
    combined_bytes = high.to_bytes(8, byteorder='big') + low.to_bytes(8, byteorder='big')
    checksum = hashlib.sha256(combined_bytes).digest()[0]
    sha256_full = hashlib.sha256(combined_bytes).hexdigest()
    return high, low





def run_kernel(program, queue, indices, batch_size):
    context = program.context
    high, low = mnemonic_to_uint64_pair(FIXED_WORDS)
    indices_buffer = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array(indices, dtype=np.uint32))
    np64 = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array([high, low], dtype=np.uint64))
    wordlist_string = b''.join(word.encode('utf-8').ljust(8, b'\0') for word in mnemo.wordlist)
    wordlist_buffer = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=wordlist_string)
    output_data = np.empty(12, dtype=np.int32)
    output_buffer = cl.Buffer(context, cl.mem_flags.WRITE_ONLY, output_data.nbytes)
    start_time = time.time()
    kernel = program.generate_combinations
    kernel.set_args(indices_buffer, wordlist_buffer, np64, np.uint64(batch_size), output_buffer)
    global_size = (WORKERS,)
    cl.enqueue_nd_range_kernel(queue, kernel, global_size, None)
    cl.enqueue_copy(queue, output_data, output_buffer).wait()
    end_time = time.time()
    elapsed_time = end_time - start_time
    seeds = WORKERS * batch_size
    media = seeds / elapsed_time
    print(f"Foram criadas {seeds:,} em {elapsed_time:.6f} seconds media {media:.6f} por seg")
    return output_data





def calculate_possible_12th_words(binary_string):
    binary_string = binary_string.zfill(128)
    entropy_bytes = int(binary_string, 2).to_bytes(16, byteorder='big')
    checksum_bits = bin(int(hashlib.sha256(entropy_bytes).hexdigest(), 16))[2:].zfill(256)[:4]
    combined_bits = binary_string + checksum_bits
    index_12th_word = int(combined_bits[-11:], 2)
    word_12th = mnemo.wordlist[index_12th_word]
    return word_12th, index_12th_word

if __name__ == "__main__":
    main()