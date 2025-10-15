
/*
 *   HMAC-SHA-512
 *    A streamlined implementation of the HMAC-SHA-512 algorithm using ulongs.
 *    Minimizes memory usage and reduces instruction count to boost performance.
 *    Works only with 6x4 bytes keys
 *       github.com/ipsbruno
 */

#define IPAD 0x3636363636363636UL
#define OPAD 0x5c5c5c5c5c5c5c5cUL

#define BITCOIN_SEED 0x426974636f696e20UL, 0x7365656400000000UL, 0, 0
#define BITCOIN_SEED_IPAD 0x745f4255595f5816UL, 0x4553535236363636UL
#define BITCOIN_SEED_OPAD 0x1e35283f3335327cUL, 0x2f3939385c5c5c5cUL

#define REPEAT_2(x) x, x
#define REPEAT_4(x) REPEAT_2(x), REPEAT_2(x)
#define REPEAT_5(x) REPEAT_4(x), x
#define REPEAT_6(x) REPEAT_4(x), REPEAT_2(x)
#define REPEAT_7(x) REPEAT_4(x), REPEAT_2(x), x
#define REPEAT_8(x) REPEAT_4(x), REPEAT_4(x)
#define REPEAT_16(x) REPEAT_8(x), REPEAT_8(x)
#define SHOW_ARR(x) x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]

void hmac_sha512_32bytes(ulong *key, ulong *message, ulong *H) {
  ulong inner[32] = {key[0] ^ IPAD,     key[1] ^ IPAD,
                     key[2] ^ IPAD,     key[3] ^ IPAD,
                     REPEAT_6(IPAD),    REPEAT_6(IPAD),
                     SHOW_ARR(message), 0x8000000000000000UL,
                     REPEAT_6(0),       1536};
  ulong outer[32] = {key[0] ^ OPAD,        key[1] ^ OPAD,   key[2] ^ OPAD,
                     key[3] ^ OPAD,        REPEAT_16(OPAD), REPEAT_4(OPAD),
                     0x8000000000000000UL, REPEAT_6(0),     1536};
  sha512_hash_two_blocks_message(inner, H);
  COPY_EIGHT(outer + 16, H);
  sha512_hash_two_blocks_message(outer, H);
}

void hmac_sha512_bitcoin_seed(ulong *message, ulong *H) {
  ulong key[4] = {BITCOIN_SEED};
  hmac_sha512_32bytes(key, message, H);
}



/* -------- util big-endian -------- */
 void wr64_be(uchar *p, ulong v){
    p[0]=(uchar)(v>>56); p[1]=(uchar)(v>>48); p[2]=(uchar)(v>>40); p[3]=(uchar)(v>>32);
    p[4]=(uchar)(v>>24); p[5]=(uchar)(v>>16); p[6]=(uchar)(v>>8);  p[7]=(uchar)(v);
}
 ulong rd64_be(const uchar *p){
    return ((ulong)p[0]<<56)|((ulong)p[1]<<48)|((ulong)p[2]<<40)|((ulong)p[3]<<32)|
           ((ulong)p[4]<<24)|((ulong)p[5]<<16)|((ulong)p[6]<<8)|((ulong)p[7]);
}

static inline int isElectrumSegwit(ulong H[8]) {
    ulong w0 = H[0];
    return ((w0 >> 52) & 0xFFFu) == 0x100u;
}
 ulong ROR(ulong x, int n){ return (x>>n)|(x<<(64-n)); }
 ulong Ch (ulong x,ulong y,ulong z){ return (x&y)^(~x&z); }
 ulong Maj(ulong x,ulong y,ulong z){ return (x&y)^(x&z)^(y&z); }
 ulong S0 (ulong x){ return ROR(x,28)^ROR(x,34)^ROR(x,39); }
 ulong S1 (ulong x){ return ROR(x,14)^ROR(x,18)^ROR(x,41); }
 ulong s0 (ulong x){ return ROR(x, 1)^ROR(x, 8)^(x>>7); }
 ulong s1 (ulong x){ return ROR(x,19)^ROR(x,61)^(x>>6); }

static const ulong Kcx[80] = {
  0x428a2f98d728ae22ULL,0x7137449123ef65cdULL,0xb5c0fbcfec4d3b2fULL,0xe9b5dba58189dbbcULL,
  0x3956c25bf348b538ULL,0x59f111f1b605d019ULL,0x923f82a4af194f9bULL,0xab1c5ed5da6d8118ULL,
  0xd807aa98a3030242ULL,0x12835b0145706fbeULL,0x243185be4ee4b28cULL,0x550c7dc3d5ffb4e2ULL,
  0x72be5d74f27b896fULL,0x80deb1fe3b1696b1ULL,0x9bdc06a725c71235ULL,0xc19bf174cf692694ULL,
  0xe49b69c19ef14ad2ULL,0xefbe4786384f25e3ULL,0x0fc19dc68b8cd5b5ULL,0x240ca1cc77ac9c65ULL,
  0x2de92c6f592b0275ULL,0x4a7484aa6ea6e483ULL,0x5cb0a9dcbd41fbd4ULL,0x76f988da831153b5ULL,
  0x983e5152ee66dfabULL,0xa831c66d2db43210ULL,0xb00327c898fb213fULL,0xbf597fc7beef0ee4ULL,
  0xc6e00bf33da88fc2ULL,0xd5a79147930aa725ULL,0x06ca6351e003826fULL,0x142929670a0e6e70ULL,
  0x27b70a8546d22ffcULL,0x2e1b21385c26c926ULL,0x4d2c6dfc5ac42aedULL,0x53380d139d95b3dfULL,
  0x650a73548baf63deULL,0x766a0abb3c77b2a8ULL,0x81c2c92e47edaee6ULL,0x92722c851482353bULL,
  0xa2bfe8a14cf10364ULL,0xa81a664bbc423001ULL,0xc24b8b70d0f89791ULL,0xc76c51a30654be30ULL,
  0xd192e819d6ef5218ULL,0xd69906245565a910ULL,0xf40e35855771202aULL,0x106aa07032bbd1b8ULL,
  0x19a4c116b8d2d0c8ULL,0x1e376c085141ab53ULL,0x2748774cdf8eeb99ULL,0x34b0bcb5e19b48a8ULL,
  0x391c0cb3c5c95a63ULL,0x4ed8aa4ae3418acbULL,0x5b9cca4f7763e373ULL,0x682e6ff3d6b2b8a3ULL,
  0x748f82ee5defb2fcULL,0x78a5636f43172f60ULL,0x84c87814a1f0ab72ULL,0x8cc702081a6439ecULL,
  0x90befffa23631e28ULL,0xa4506cebde82bde9ULL,0xbef9a3f7b2c67915ULL,0xc67178f2e372532bULL,
  0xca273eceea26619cULL,0xd186b8c721c0c207ULL,0xeada7dd6cde0eb1eULL,0xf57d4f7fee6ed178ULL,
  0x06f067aa72176fbaULL,0x0a637dc5a2c898a6ULL,0x113f9804bef90daeULL,0x1b710b35131c471bULL,
  0x28db77f523047d84ULL,0x32caab7b40c72493ULL,0x3c9ebe0a15c9bebcULL,0x431d67c49c100d4cULL,
  0x4cc5d4becb3e42b6ULL,0x597f299cfc657e2aULL,0x5fcb6fab3ad6faecULL,0x6c44198c4a475817ULL
};

static void sha512_compress_ex(ulong st[8], const uchar block[128]){
    ulong W[80];
    int t;
    for (t=0;t<16;++t) W[t]=rd64_be(block+8*t);
    for (t=16;t<80;++t) W[t]=s1(W[t-2])+W[t-7]+s0(W[t-15])+W[t-16];
    ulong a=st[0],b=st[1],c=st[2],d=st[3],e=st[4],f=st[5],g=st[6],h=st[7];
    for (t=0;t<80;++t){
        ulong T1=h+S1(e)+Ch(e,f,g)+Kcx[t]+W[t];
        ulong T2=S0(a)+Maj(a,b,c);
        h=g; g=f; f=e; e=d+T1;
        d=c; c=b; b=a; a=T1+T2;
    }
    st[0]+=a; st[1]+=b; st[2]+=c; st[3]+=d; st[4]+=e; st[5]+=f; st[6]+=g; st[7]+=h;
}

/* -------- HMAC("Seed version") com mensagem variável -------- */
void hmac_sha512_seed_c99_ex(const uchar *msg, size_t mlen, ulong H[8]){
    /* IV */
    ulong st[8] = {
        0x6a09e667f3bcc908ULL,0xbb67ae8584caa73bULL,0x3c6ef372fe94f82bULL,0xa54ff53a5f1d36f1ULL,
        0x510e527fade682d1ULL,0x9b05688c2b3e6c1fULL,0x1f83d9abfb41bd6bULL,0x5be0cd19137e2179ULL
    };
    /* ---------- Seed version Electrum checksum ---------- */
    static const uchar KEY[12] = { 'S','e','e','d',' ','v','e','r','s','i','o','n' };
    uchar blk[128];
    uchar last[128];
    size_t i, j;
    /* ---------- INNER: processa K'⊕IPAD ---------- */
    for (i=0;i<128;++i) blk[i] = 0x36u;        /* fill 0x36 */
    for (i=0;i<12;++i)  blk[i] ^= KEY[i];      /* XOR a chave "Seed version" */
    sha512_compress_ex(st, blk);
    /* Processa a mensagem em blocos completos */
    i = 0;
    while (i + 128 <= mlen) {
        /* copiar 128 bytes de msg+i para blk (sem memcpy) */
        for (j=0;j<128;++j) blk[j] = msg[i+j];
        sha512_compress_ex(st, blk);
        i += 128;
    }
    /* Bloco final do inner: resto + 0x80 + zeros + length( (128 + mlen) * 8 ) */
    /* resta = mlen - i bytes */
    {
        size_t rem = mlen - i;
        for (j=0;j<rem;++j) last[j] = msg[i+j];
        if (rem < 128) last[rem] = 0x80u;
        for (j=rem+1; j<128; ++j) last[j] = 0u;  /* zera o resto */
        /* comprimento em bits: (128 + mlen) * 8 como inteiro de 128 bits big-endian */
        /* hi = (mlen >> 61), lo = (mlen << 3) + 1024; se carry em +1024, hi++ */
        ulong lo = ((ulong)mlen << 3) + 1024ULL;
        ulong hi = (ulong)((mlen >> 61) & 0x7FFFFFFFFFFFFFFFULL);
        if (lo < 1024ULL) hi++;
        if (rem <= (128 - 1 - 16)) {
            /* cabe o length neste bloco */
            wr64_be(last + 128 - 16, hi);
            wr64_be(last + 128 - 8,  lo);
            sha512_compress_ex(st, last);
        } else {
            /* precisa de dois blocos finais */
            sha512_compress_ex(st, last);          /* primeiro: resto + 0x80 + zeros */
            for (j=0;j<128;++j) blk[j] = 0u;    /* segundo: só length */
            wr64_be(blk + 128 - 16, hi);
            wr64_be(blk + 128 - 8,  lo);
            sha512_compress_ex(st, blk);
        }
    }
    /* Exporta o digest interno em bytes para alimentar o outer */
    uchar inner_digest[64];
    for (i=0;i<8;++i) wr64_be(inner_digest + 8*i, st[i]);
    /* ---------- OUTER: SHA512( (K'⊕OPAD) || inner_digest ) ---------- */
    /* Reinicia IV */
    st[0]=0x6a09e667f3bcc908ULL; st[1]=0xbb67ae8584caa73bULL;
    st[2]=0x3c6ef372fe94f82bULL; st[3]=0xa54ff53a5f1d36f1ULL;
    st[4]=0x510e527fade682d1ULL; st[5]=0x9b05688c2b3e6c1fULL;
    st[6]=0x1f83d9abfb41bd6bULL; st[7]=0x5be0cd19137e2179ULL;
    for (i=0;i<128;++i) blk[i] = 0x5cu;
    for (i=0;i<12;++i)  blk[i] ^= KEY[i];
    sha512_compress_ex(st, blk);
    for (i=0;i<64;++i) last[i] = inner_digest[i];
    last[64] = 0x80u;
    for (i=65;i<128;++i) last[i]=0u;
    wr64_be(last + 128 - 16, 0ULL);
    wr64_be(last + 128 - 8,  1536ULL);
    sha512_compress_ex(st, last);
    for (i=0;i<8;++i) H[i] = st[i];
}

