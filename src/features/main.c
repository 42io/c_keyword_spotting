#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "fe.h"

/*********************************************************************/

typedef struct 
{
  char     chunk_id[4];
  uint32_t chunk_size;
  char     format[4];
  char     fmtchunk_id[4];
  uint32_t fmtchunk_size;
  uint16_t audio_format;
  uint16_t num_channels;
  uint32_t sample_rate;
  uint32_t byte_rate;
  uint16_t block_align;
  uint16_t bits_per_sample;
  char     datachunk_id[4];
  uint32_t datachunk_size;
} wave_header_t;

/*********************************************************************/

static void read_wave_fd(FILE *fd, char* dest, size_t sz)
{
  wave_header_t header;

  assert(fread(&header, 1, sizeof header, fd) == sizeof header);
  assert(strncmp(header.chunk_id, "RIFF", sizeof header.chunk_id) == 0);
  assert(strncmp(header.format, "WAVE", sizeof header.format) == 0);
  assert(header.audio_format == 1);
  assert(header.num_channels == 1);
  assert(header.sample_rate == 16000);
  assert(header.bits_per_sample == 16);
  assert(header.datachunk_size == 32000);
  assert(fread(dest, 1, sz, fd) == sz);
}

/*********************************************************************/

static void read_wave(const char* path, char* dest, size_t sz)
{
  FILE *fd = path && strcmp(path, "-") ? fopen(path, "r") : stdin;
  assert(fd);

  read_wave_fd(fd, dest, sz);

  if(fd != stdin)
  {
    fclose(fd);
  }
}

/*********************************************************************/

static void extract_print_features(int16_t* samples, size_t n_samples)
{
  int n_frames, n_items_in_frame;
  csf_float *feat;

  n_frames = n_items_in_frame = 0;
  feat = fe_mfcc_16k_16b_mono(samples, n_samples, &n_frames, &n_items_in_frame);
  assert(n_frames == 49);
  assert(n_items_in_frame == 13);
  assert(feat);

  for(int i = 0, idx = 0; i < n_frames; i++)
  {
    for(int k = 0; k < n_items_in_frame; k++, idx++)
    {
      if(k)
      {
        printf(" ");
      }
      printf("%.5f", feat[idx]);
    }
    printf("\n");
  }

  free(feat);
}

/*********************************************************************/

int main(int argc, const char *argv[])
{
  int16_t sec[16000]; // one second

  read_wave(argc > 1 ? argv[1] : NULL, (char*)sec, sizeof sec);
  extract_print_features(sec, sizeof sec / sizeof sec[0]);

  return 0;
}

/*********************************************************************/