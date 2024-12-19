import numpy as np
import pyopencl as cl
from hashlib import pbkdf2_hmac
import time
import string
import random

def load_program_source(filename):
    with open(filename, 'r') as f:
        return f.read()

def initialize_opencl():
    try:
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



def pbkdf2_python(key):
    # Calculando o PBKDF2 em Python para comparação
    return pbkdf2_hmac('sha512', key,  "mnemonic".encode('utf-8'),2048)

def run_kernel(program, queue, string):
    context = program.context



    string_buffer = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=(string))
    ss = str(pbkdf2_python(string).hex()).encode()
    result_buffer = cl.Buffer(context, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=ss)

    kernel = program.pbkdf2_hmac_sha512_test
    kernel.set_args(result_buffer, string_buffer)

    cl.enqueue_nd_range_kernel(queue, kernel, (1,), None).wait()


    return 

def ulong_list_to_string(ulong_list):
    byte_list = b''.join([ulong.to_bytes(8, byteorder='little') for ulong in ulong_list])
    return byte_list.decode('utf-8').rstrip('\x00')  # Remove padding zero bytes

if __name__ == "__main__":
    platforms = cl.get_platforms()
    devices = platforms[0].get_devices()

    device = devices[0]

    context, queue = initialize_opencl()
    program = build_program(context, "./kernel/common.cl",  "./kernel/sha512_hmac.cl", "./kernel/sha256.cl", "./kernel/main.cl")

    for i in range(10000):
        strs = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(95)).encode()
        run_kernel(program, queue, strs)
