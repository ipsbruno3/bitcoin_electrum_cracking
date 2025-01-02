import time
import numpy as np
import pyopencl as cl
from mnemonic import Mnemonic
from concurrent.futures import ThreadPoolExecutor, as_completed

import os
os.environ['PYOPENCL_COMPILER_OUTPUT'] = '1'

def info():
        print('\n' + '=' * 60 + '\nOpenCL Platforms and Devices')
        for i,platformNum in enumerate(cl.get_platforms()):
            print('=' * 60)
            print('Platform %d - Name: ' %i + platformNum.name)
            print('Platform %d - Vendor: ' %i + platformNum.vendor)
            print('Platform %d - Version: ' %i + platformNum.version)
            print('Platform %d - Profile: ' %i + platformNum.profile)

            for device in platformNum.get_devices():
                print(' ' + '-' * 56)
                print(' Device - Name: ' + device.name)
                print(' Device - Type: ' + cl.device_type.to_string(device.type))
                print(' Device - Max Clock Speed: {0} Mhz'.format(device.max_clock_frequency))
                print(' Device - Compute Units: {0}'.format(device.max_compute_units))
                print(' Device - Local Memory: {0:.0f} KB'.format(device.local_mem_size / 1024.0))
                print(' Device - Constant Memory: {0:.0f} KB'.format(device.max_constant_buffer_size / 1024.0))
                print(' Device - Global Memory: {0:.0f} GB'.format(device.global_mem_size / 1073741824.0))
                print(' Device - Max Buffer/Image Size: {0:.0f} MB'.format(device.max_mem_alloc_size / 1048576.0))
                print(' Device - Max Work Group Size: {0:.0f}'.format(device.max_work_group_size))
                print('\n')
                
info()

mnemo = Mnemonic("english")

FIXED_WORDS = "actual action amused black abandon adjust winter abandon abandon abandon abandon abandon".split()
DESTINY_WALLET = "bc1q9nfphml9vzfs6qxyyfqdve5vrqw62dp26qhalx"
FIXED_SEED = "actual action amused black abandon adjust winter "

block_fix = len(FIXED_SEED)-(len(FIXED_SEED)%8)
global_workers = 24_000_000
repeater_workers = 1_000_000
local_workers = 256

tw = (global_workers,)
tt = (local_workers,)

print(f"Rodando OpenCL com {global_workers} GPU THREADS e {repeater_workers * global_workers}")

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

def run_kernel(program, queue):
    context = program.context
    kernel = program.verify
    elements = global_workers * 10
    bytes = elements * 8
    
    
    
    inicio = time.perf_counter()
    high, low = mnemonic_to_uint64_pair(words_to_indices(FIXED_WORDS))
    high_buf = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array([high], dtype=np.uint64))
    low_buf = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.array([low], dtype=np.uint64))
    output_buf = cl.Buffer(context, cl.mem_flags.WRITE_ONLY, bytes)
    kernel.set_args(high_buf, low_buf, output_buf)

    cl.enqueue_nd_range_kernel(queue, kernel, tw,tt).wait()

    
    resultado = global_workers / (time.perf_counter() - inicio)
    result = np.empty(elements, dtype=np.uint64)  # Adjust the result array 
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
    low = int(binary_string[:64], 2)
    high = int(binary_string[64:], 2)
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
        print_device_info(device)
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