# main.py
import gzip, os
import hashlib
from collections import defaultdict
import numpy as np
import pyopencl as cl
from dotenv import load_dotenv
from mnemonic import Mnemonic
from collections import defaultdict
import os, gzip, pickle


plats = cl.get_platforms()
dev = None
for p in plats:
    gpus = [d for d in p.get_devices() if d.type & cl.device_type.GPU]
    if gpus:
        dev = gpus[0]
        break
if dev is None:
    dev = plats[0].get_devices()[0]

ctx = cl.Context([dev])
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)

# nome do device
device_name = dev.name.strip()
platform_name = dev.platform.name.strip()

print(f"[INFO] Usando plataforma: {platform_name}")
print(f"[INFO] Device ativo: {device_name}")


# ----------------- Config básica -----------------
mnemo = Mnemonic("english")
load_dotenv()
SEED = os.getenv("SEED", "? ? ? ? ? ? ? ? ? ? ?")
MAX_GROUPS = int(os.getenv("MAX_GROUPS") or 1_000_000)
MAX_RETRIES = int(os.getenv("MAX_RETRIES") or 1000)
INIT = int(os.getenv("INIT") or 0)
MAX_HITS = int(os.getenv("MAX_HITS") or 100_000)

print(f"Seed para Buscar: {SEED}")


# ----------------- Bech32 helpers ----------------
from bech32 import bech32_decode, convertbits

def decode_addr(addr: str):
    out = bech32_decode(addr)
    if not out or out[0] is None:
        raise ValueError("Bech32 inválido")
    hrp, data = out[0], out[1]
    if not data: raise ValueError("Sem payload")
    ver = data[0]
    prog = bytes(convertbits(data[1:], 5, 8, False) or [])
    if not (0 <= ver <= 16): raise ValueError("Versão witness inválida")
    if not (2 <= len(prog) <= 40): raise ValueError("Tamanho do witness program inválido")
    if ver == 0 and len(prog) not in (20, 32): raise ValueError("v0 exige 20/32 bytes")
    return hrp, ver, prog


# ----------------- Tag64 (host) -------------------
def tag64_from_h160_prefix8(h160: bytes) -> int:
    return int.from_bytes(h160[:8], "little")

def tag64_fold_32(prog32: bytes) -> int:
    a = int.from_bytes(prog32[0:8],  "little")
    b = int.from_bytes(prog32[8:16], "little")
    c = int.from_bytes(prog32[16:24],"little")
    d = int.from_bytes(prog32[24:32],"little")
    return a ^ b ^ c ^ d

from collections import defaultdict
import os, gzip, pickle

# Assumo que você já tem estas duas:
# def decode_addr(addr: str): -> (hrp: str, ver: int, prog: bytes)
# def tag64_from_h160_prefix8(h160: bytes) -> int

def montar_indice_tag64(base_gz: str, hrps=("bc", "tb"), usar_cache=True, force=False):
    hrps = tuple(h.lower() for h in hrps)
    prefixes = tuple(h + "1" for h in hrps)

    # cache: um arquivo ao lado do .gz, com HRPs no nome
    hrps_key = "-".join(sorted(hrps))
    cache_file = f"{base_gz}.{hrps_key}.t64.pkl.gz"

    # tenta ler do cache se for mais novo que o .gz
    if usar_cache and not force and os.path.exists(cache_file):
        try:
            if os.path.getmtime(cache_file) >= os.path.getmtime(base_gz):
                with gzip.open(cache_file, "rb") as f:
                    index, addr_set, stats = pickle.load(f)
                # garante tipo no retorno
                if not isinstance(index, defaultdict):
                    index = defaultdict(list, index)
                return index, set(addr_set), stats
        except Exception:
            pass  # cache quebrado? ignora e reconstrói

    # reconstrói do zero
    index = defaultdict(list)
    addr_set = set()
    total = valid = 0

    with gzip.open(base_gz, "rt", encoding="utf-8", errors="ignore") as f:
        for line in f:
            s = line.strip()
            if not s:
                continue
            total += 1
            addr = s.split(None, 1)[0]
            if not addr.startswith(prefixes):
                continue
            try:
                hrp, ver, prog = decode_addr(addr)
            except Exception:
                continue
            if hrp not in hrps or ver != 0 or len(prog) != 20:
                continue
            t64 = tag64_from_h160_prefix8(prog)
            index[t64].append((ver, prog, addr))
            addr_set.add(addr)
            valid += 1

    stats = {"linhas_lidas": total, "enderecos_v0": valid, "tags_unicas": len(index)}

    # salva cache (bem simples)
    if usar_cache:
        try:
            with gzip.open(cache_file, "wb") as f:
                # salva como dict normal para não depender do pickle de defaultdict
                pickle.dump((dict(index), addr_set, stats), f, protocol=pickle.HIGHEST_PROTOCOL)
        except Exception:
            pass  # se falhar salvar, paciência

    return index, addr_set, stats

def build_program(ctx, kernel_path="./kernel/main.cl"):
    with open(kernel_path, "r", encoding="utf-8") as f:
        src = f.read()
    return cl.Program(ctx, src).build(options="-I ./kernel")


HIT_DTYPE = np.dtype([
    ('tag64','<u8'),
    ('widx', '<u2', (12,)),   
])

def words_from_indices(indices12: np.ndarray) -> str:
    return " ".join(mnemo.wordlist[int(x)] for x in indices12.tolist())

def run(h, l, i,
        index, addr_set,
        kernel_path="./kernel/main.cl",
        N=MAX_GROUPS,
        LWS=64,
        MAX_HITS=MAX_HITS):
    plats = cl.get_platforms()
    if not plats: raise RuntimeError("Nenhuma plataforma OpenCL encontrada.")
    dev = None
    for p in plats:
        gpus = [d for d in p.get_devices() if d.type & cl.device_type.GPU]
        if gpus:
            dev = gpus[0]; break
    if dev is None:
        dev = plats[0].get_devices()[0]
    ctx = cl.Context([dev])
    queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)

    prg = build_program(ctx, kernel_path)
    k = prg.verify

    first_buf = cl.Buffer(ctx, cl.mem_flags.READ_ONLY  | cl.mem_flags.COPY_HOST_PTR,
                          hostbuf=np.array([(MAX_GROUPS*i)], dtype=np.uint64))
    H_buf     = cl.Buffer(ctx, cl.mem_flags.READ_ONLY  | cl.mem_flags.COPY_HOST_PTR,
                          hostbuf=np.array([h], dtype=np.uint64))
    L_buf     = cl.Buffer(ctx, cl.mem_flags.READ_ONLY  | cl.mem_flags.COPY_HOST_PTR,
                          hostbuf=np.array([l], dtype=np.uint64))

    hits_buf      = cl.Buffer(ctx, cl.mem_flags.READ_WRITE, size=HIT_DTYPE.itemsize * MAX_HITS)
    out_count_buf = cl.Buffer(ctx, cl.mem_flags.READ_WRITE, size=4)
    cl.enqueue_fill_buffer(queue, out_count_buf, np.uint32(0), 0, 4)
    k.set_args(first_buf, H_buf, L_buf, hits_buf, out_count_buf, np.uint32(MAX_HITS))
    if N % LWS != 0:
        raise ValueError(f"N ({N}) precisa ser múltiplo de LWS ({LWS})")
    ev = cl.enqueue_nd_range_kernel(queue, k, (N,), (LWS,))
    ev.wait()
    try:
        exec_ms = (ev.profile.end - ev.profile.start) * 1e-6
    except Exception:
        exec_ms = float('nan')
    count_host = np.empty(1, dtype=np.uint32)
    cl.enqueue_copy(queue, count_host, out_count_buf).wait()
    n = int(min(count_host[0], MAX_HITS))
    hits = np.empty(n, dtype=HIT_DTYPE)
    if n:
        cl.enqueue_copy(queue, hits, hits_buf).wait()
    tags_ok = 0
    candidatos = 0
    matched = []
    for rec in hits:  
        t64 = int(rec['tag64'])       
        bucket = index.get(t64, [])
        if not bucket:
            continue

        tags_ok += 1
        candidatos += len(bucket)
        mn = words_from_indices(rec['widx'])

        for (_ver, _prog, addr) in bucket:
            matched.append({"addr": addr,  "mnemo": mn})
    itps = (N / (exec_ms / 1000.0)) if exec_ms == exec_ms else float('nan')
    #print(f" {itps:,.0f} it/s |  candidatos={candidatos} | n={n}")

    return {
        "exec_ms": exec_ms,
        "itps": f" {itps:,.0f} it/s",   
        "tags_encontradas": tags_ok,
        "candidatos": candidatos,
        "enderecos": matched[:50],
        "high":h,
        "low": (MAX_GROUPS * i)+l,
        "n_hits": n,
    },

# ----------------- BIP39 bits util ----------------
def mnemonic_to_uint64_pair(indices):
    bits = ''.join(f"{index:011b}" for index in indices)[:-4]
    bits = bits.ljust(128, '0')
    high = int(bits[:64],  2)
    low  = int(bits[64:],  2)
    return high, low


def words_to_indices(words):
    return np.array([mnemo.wordlist.index(w) for w in words if w in mnemo.wordlist],
                    dtype=np.int32)
 
# ----------------- Execução exemplo ----------------
if __name__ == "__main__":
    print("Lendo arquivo com todos endereços bech32 (P2WPKH v0)...")
    index, addr_set, stats = montar_indice_tag64("Bitcoin_addresses_LATEST.txt.gz")
    print(f"Index pronto: {stats}")

    FIXED_WORDS = SEED.replace('?', 'abandon').split()
    indices = words_to_indices(FIXED_WORDS)
    print("Seed Indices:", indices)

    high, low = mnemonic_to_uint64_pair(indices)

    i = INIT
    while(i < MAX_RETRIES): 
        res = run(high, low, i, index, addr_set)     
        print(device_name, i, res)   
        i+=1
    
    
