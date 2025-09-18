import time
import numpy as np
import pyopencl as cl
from mnemonic import Mnemonic
from concurrent.futures import ThreadPoolExecutor, as_completed

import time
import hashlib
import hmac
seed_hex = "db4c5960c73d510cfd34c8ccbab2058b893e2a6c2af88140982e4f1d028fc6a56ba3e48738fca465cd5014a41169558ea8360ca1d8336fc6e5b946e3e0fdf012"

# Converter a seed para bytes
seed_bytes = bytes.fromhex(seed_hex)

# Chave "Bitcoin seed" como bytes
key = b"Bitcoin seed"

# Calcular HMAC-SHA512
hmac_result = hmac.new(key, seed_bytes, hashlib.sha512).digest()

# Separar em Master Private Key e Chain Code
master_private_key = hmac_result[:32].hex()
chain_code = hmac_result[32:].hex()

# Mostrar os resultados
print(f"Em Python pegando o HMAC-SHA512 Result em HEX: {hmac_result.hex()}")


# Converter 
import os
os.environ['PYOPENCL_COMPILER_OUTPUT'] = '1'
import random

BIP32_E8_ID = 1;
BIP39_EIGHT_LEN = ['abstract', 'accident', 'acoustic', 'announce', 'artefact', 'attitude', 'bachelor', 'broccoli', 'business', 'category', 'champion', 'cinnamon', 'congress', 'consider', 'convince', 'cupboard', 'daughter', 'december', 'decorate', 'decrease', 'describe', 'dinosaur', 'disagree', 'discover', 'disorder', 'distance', 'document', 'electric', 'elephant', 'elevator', 'envelope', 'evidence', 'exchange', 'exercise', 'favorite', 'february', 'festival', 'frequent', 'hedgehog', 'hospital', 'identify', 'increase', 'indicate', 'industry', 'innocent', 'interest', 'kangaroo', 'language', 'marriage', 'material', 'mechanic', 'midnight', 'mosquito', 'mountain', 'multiply', 'mushroom', 'negative', 'ordinary', 'original', 'physical', 'position', 'possible', 'practice', 'priority', 'property', 'purchase', 'question', 'remember', 'resemble', 'resource', 'response', 'scissors', 'scorpion', 'security', 'sentence', 'shoulder', 'solution', 'squirrel', 'strategy', 'struggle', 'surprise', 'surround', 'together', 'tomorrow', 'tortoise', 'transfer', 'umbrella', 'universe']

mnemo = Mnemonic("english")

FIXED_WORDS = f"abandon abandon abandon abandon abandon abandon abandon {BIP39_EIGHT_LEN[BIP32_E8_ID]} ? ? ? ?".replace('?', "abandon").split()
print(FIXED_WORDS)
DESTINY_WALLET = "bc1q9nfphml9vzfs6qxyyfqdve5vrqw62dp26qhalx"

<<<<<<< HEAD

repeater_workers = 1
local_workers = 256
global_workers = 512
=======
block_fix = len(FIXED_SEED)-(len(FIXED_SEED)%8)
global_workers = 24_000_000
repeater_workers = 1_000_000
local_workers = 256
>>>>>>> parent of 197c93f (atualização desempenho pbkdf2)

tw = (global_workers,)
tt = (local_workers,)


print(f"Rodando OpenCL com {global_workers} GPU THREADS e {repeater_workers * global_workers}")

<<<<<<< HEAD
=======
# Função para imprimir as informações do dispositivo
def print_device_info(device):
    print(f"Device Name: {device.name.strip()}")
    print(f"Device Type: {'GPU' if device.type == cl.device_type.GPU else 'CPU'}")
    print(f"OpenCL Version: {device.version.strip()}")
    print(f"Driver Version: {device.driver_version.strip()}")
    print(f"Max Compute Units: {device.max_compute_units}")
    print(f"Max Work Group Size: {device.max_work_group_size}")
    print(f"Max Work Item Dimensions: {device.max_work_item_dimensions}")
    print(f"Max Work Item Sizes: {device.max_work_item_sizes}")
    print(f"Global Memory Size: {device.global_mem_size / (1024 ** 2):.2f} MB")
    print(f"Local Memory Size: {device.local_mem_size / 1024:.2f} KB")
    print(f"Max Clock Frequency: {device.max_clock_frequency} MHz")
    print(f"Address Bits: {device.address_bits}")
    print(f"Available: {'Yes' if device.available else 'No'}")
>>>>>>> parent of 197c93f (atualização desempenho pbkdf2)

    
def run_kernel(program, queue):
    context = program.context
    kernel = program.verify
    elements = global_workers * 12000
    bytes = elements * 8
    inicio = time.perf_counter()
    indices = words_to_indices(FIXED_WORDS)
    print(indices)
    high, low = mnemonic_to_uint64_pair(indices)
    print(high,low)
    high_buf = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array([high], dtype=np.uint64))
    low_buf = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array([low], dtype=np.uint64))
    p = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array([1], dtype=np.uint32))

 
    output_buf = cl.Buffer(context, cl.mem_flags.WRITE_ONLY, bytes)
<<<<<<< HEAD
    kernel.set_args(p, high_buf, low_buf, output_buf)
    
    event = cl.enqueue_nd_range_kernel(queue, kernel, tw, tt)
    
    event.wait()
    start_time = event.profile.start
    end_time = event.profile.end
    execution_time = (end_time - start_time) * 1e-6  # Em milissegundos
    print(f"Tempo de execução do kernel: {execution_time:.3f} ms")
    resultado = (global_workers) / (time.perf_counter() - inicio)
    result = np.empty(elements, dtype=np.uint64) 
=======
    kernel.set_args(high_buf, low_buf, output_buf)

    cl.enqueue_nd_range_kernel(queue, kernel, tw,tt).wait()

    
    resultado = global_workers / (time.perf_counter() - inicio)
    result = np.empty(elements, dtype=np.uint64)  # Adjust the result array 
>>>>>>> parent of 197c93f (atualização desempenho pbkdf2)
    cl.enqueue_copy(queue, result, output_buf).wait()

    print(f"Tempo de execução: {resultado:.2f} por seguno")


def carregar_wallets():
    memoria = {}
    print("Carregando endereços Bitcoin na Memória")
    with open("wallets.tsv", "r") as arquivo:
        for linha in arquivo:
            linha = linha.strip()
            if linha:
                try:
                    addr, saldo = linha.split()
                    memoria[addr] = float(saldo)
                except ValueError:
                    continue

    addr_busca = "0x1234abcd"
    if addr_busca in memoria:
        print(f"Saldo de {addr_busca}: {memoria[addr_busca]}")
    else:
        print(f"Endereço {addr_busca} não encontrado.")


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
    binary_string = ''.join(f"{index:011b}" for index in indices)[:-4]
    binary_string = binary_string.ljust(128, '0')
    high = int(binary_string[:64], 2)
    low = int(binary_string[64:], 2)
    return high, low


def uint64_pair_to_mnemonic(high, low):
    binary_string = f"{high:064b}{low:064b}"
    indices = [int(binary_string[i:i+11], 2)
               for i in range(0, len(binary_string), 11)]
    words = [mnemo.wordlist[index]
             for index in indices if index < len(mnemo.wordlist)]
    seed = ' '.join(words)
    return seed


def main():
    try:
        platforms = cl.get_platforms()
        devices = platforms[0].get_devices()
        device = devices[0]

        context = cl.Context([device])
        queue = cl.CommandQueue(context)
        print(f"Dispositivo: {device.name}")
        program = build_program(context,
                                "./kernel/common.cl",
                                "./kernel/sha256.cl",
                                "./kernel/sha512_hmac.cl",
                                "./kernel/main.cl"
                                )

        run_kernel(program, queue)

        print("Kernel executado com sucesso.")
    except Exception as e:
        print(f"Erro ao compilar o programa OpenCL 1: {e}")
    return


def load_program_source(filename):
    with open(filename, 'r') as f:
        content = f.read()
    return content



if __name__ == "__main__":
    #carregar_wallets()
    main()
