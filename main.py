import numpy as np
import pyopencl as cl
from mnemonic import Mnemonic
import hashlib
import time
import hmac



mnemo = Mnemonic("english")
BATCH_SIZE = 100000

FIXED_WORDS = "squirrel civil denial manage host wire love abandon abandon abandon abandon".split()
WORKERS = 2048









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
        source_code += load_program_source(filename) + "\n\n\n"
    return cl.Program(context, source_code).build()





def words_to_indices(words):
    indices = []
    for word in words:
        if word in mnemo.wordlist:
            indices.append(mnemo.wordlist.index(word))
    return np.array(indices, dtype=np.int32)





def mnemonic_to_uint64_pair(indices):
    """Converte os índices em dois valores uint64: high e low."""
    binary_string = ''.join(f"{index:011b}" for index in indices)[:-4]  # Remove os últimos 4 bits (checksum)
    # Certifica que a string tem no mínimo 64 bits para high e low
    binary_string = binary_string.ljust(128, '0')
    high = int(binary_string[:64], 2)
    low = int(binary_string[64:], 2)
    return high, low






def run_kernel(program, queue, indices, batch_size):
    context = program.context
    high, low = mnemonic_to_uint64_pair(words_to_indices(FIXED_WORDS))
    indices_buffer = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array(indices, dtype=np.uint32))
    np64 = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array([high, low], dtype=np.uint64))
    print(f"String iniciada: {high}, {low}")
    output_data = np.empty(12, dtype=np.int32)
    output_buffer = cl.Buffer(context, cl.mem_flags.WRITE_ONLY, output_data.nbytes)
    start_time = time.time()
    kernel = program.generate_combinations
    kernel.set_args(indices_buffer, np64, np.uint64(batch_size), output_buffer)
    global_size = (WORKERS,)
    cl.enqueue_nd_range_kernel(queue, kernel, global_size, None)
    cl.enqueue_copy(queue, output_data, output_buffer).wait()
    end_time = time.time()
    elapsed_time = end_time - start_time
    seeds = WORKERS * batch_size
    media = seeds / elapsed_time
    
    print(f"Foram criadas {seeds:,} em {elapsed_time:.6f} seconds media {media:.6f} por seg")
    return output_data




if __name__ == "__main__":
    main()