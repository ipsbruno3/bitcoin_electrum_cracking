#include "kernel/bip39.cl"
#include "kernel/common.cl"
#include "kernel/ec.cl"
#include "kernel/ripemd_beech.cl"
#include "kernel/sha256.cl"
#include "kernel/sha512.cl"

/* ===== Portáveis: atômicos 1.2 vs 2.0 ===== */
#if __OPENCL_C_VERSION__ >= 200
  // OpenCL 2.0+: use C11 atomics
  #define OUTCNT_ARG      __global atomic_uint *
  #define OUTCNT_FETCH()  atomic_fetch_add_explicit(out_count, 1u, memory_order_relaxed, memory_scope_device)
#else
  // OpenCL 1.2: legacy atomics
  #pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable
  #pragma OPENCL EXTENSION cl_khr_local_int32_base_atomics  : enable
  #define OUTCNT_ARG      __global volatile uint *
  #define OUTCNT_FETCH()  atomic_inc(out_count)   /* retorna valor anterior, incrementa mod 2^32 */
#endif

typedef struct {
    ulong  tag64;     // 8
    ushort widx[12];  // 24 -> total 40 bytes
} hit_t;

/* --- kernel --- */
__kernel void verify(__global const ulong *first,
                     __global const ulong *H,
                     __global const ulong *L,
                     __global hit_t *out_hits,
                     OUTCNT_ARG out_count,          // compatível com CL1.2/2.0
                     const uint max_hits)
{
    const uint gid = get_global_id(0);

    const ulong memHigh  = H[0];
    const ulong firstMem = L[0];
    const ulong memLow   = firstMem + (ulong)gid + first[0];

    uint  seedNum[16] = {0};
    uchar mnemonicString[128] = {0};
    uint  offset = 0;

    prepareSeedNumber(seedNum, memHigh, memLow);
    prepareSeedString(seedNum, mnemonicString, offset);

    if (offset == 0) return;              // proteção
    const size_t mlen = (size_t)offset - 1;

    ulong G[8] = {0};
    hmac_sha512_seed_c99_ex(mnemonicString, mlen, G);

    if (!isElectrumSegwit(G)) return;

    // Derivação BIP32 m/0'/0/i
    ulong mnemonicLong[16]   = {0};
    ulong inner_data[32]     = {0};
    ulong outer_data[32]     = {0};
    ulong hmacSeedOutput[8]  = {0};
    ulong pbkdLong[16]       = {0};

    ucharLong(mnemonicString, mlen, mnemonicLong, 0);

    #pragma unroll
    for (int lid = 0; lid < 16; lid++) {
        inner_data[lid] = mnemonicLong[lid] ^ IPAD;
        outer_data[lid] = mnemonicLong[lid] ^ OPAD;
    }
    // constantes (mesmas que você já usava)
    outer_data[16] = 6655295901103053916UL;
    inner_data[16] = 0x656c65637472756dULL;
    inner_data[17] = 0x0000000180000000ULL;
    outer_data[24] = 9223372036854775808UL;
    outer_data[31] = 1536UL;
    inner_data[31] = 1120UL;

    pbkdf2_hmac_sha512_long(inner_data, outer_data, pbkdLong);
    hmac_sha512_bitcoin_seed(pbkdLong, hmacSeedOutput);

    ulong kc[4] = {0}, cc[4] = {0};
    uint  X[8]  = {0}, Y[8]  = {0};

    if (!derive_m_0h_0_i_pub(hmacSeedOutput, 0u, kc, cc, X, Y)) return;

    const ulong t64 = b32sw_tag64_from_xy_le(X, Y);  // sua função de tag 64-bit

    // ring buffer: pega slot e escreve
    const uint slot = (uint)OUTCNT_FETCH();
    if (slot >= max_hits) {
        // opcional: marcar overflow
        return;
    }

    out_hits[slot].tag64 = t64;

    for (int j = 0; j < 12; ++j) {
        out_hits[slot].widx[j] = seedNum[j];
    }

    #ifdef DEBUG_PRINT
    if ((gid & 0xFFFFFFu) == 0u) {
        // %u para uint; %016lx para ulong em hexa 64-bit
        printf("gid=%u tag64=%016lx\n", gid, (ulong)t64);
    }
    #endif
}
