#define NUM_WORDS 2048
#define SEED_SIZE 12

__kernel void generate_combinations(__global uint *index, __global ulong *seed, ulong batchsize, __global ulong2 *output)
{
  int idx = get_global_id(0);

  //printf("Chegou do Python %d %lu %lu\n", idx, seed[0], seed[1]);
  ulong seed_max = seed[0];
  ulong seed_min = seed[1] + (idx * batchsize);
  ulong final = batchsize;

  uint indices[12] = {0};

  indices[0] = (seed_max & (2047UL << 53UL)) >> 53UL;
  indices[1] = (seed_max & (2047UL << 42UL)) >> 42UL;
  indices[2] = (seed_max & (2047UL << 31UL)) >> 31UL;
  indices[3] = (seed_max & (2047UL << 20UL)) >> 20UL;
  indices[4] = (seed_max & (2047UL << 9UL)) >> 9UL;
  indices[5] = (((seed_max << 55UL) >> 53UL)) | (((seed_min & (3UL << 62UL)) >> 62UL));
  indices[6] = (seed_min & (2047UL << 51UL)) >> 51UL;

  for (ulong iterator = 0; iterator < final; ++iterator, seed_min++)
  {
    indices[7] = (seed_min & (2047UL << 40UL)) >> 40UL;
    indices[8] = (seed_min & (2047UL << 29UL)) >> 29UL;
    indices[9] = (seed_min & (2047UL << 18UL)) >> 18UL;
    indices[10] = (seed_min & (2047UL << 7UL)) >> 7UL;    
    indices[11] = ((seed_min << 57) >> 53) | sha256_from_ulong(seed_max, seed_min) >> 4;
    if(seed_min % 1000000==0) {
      //print_words_from_indices(indices);
    }

   
  }
}