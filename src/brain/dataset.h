#pragma once

#include <stdint.h>

/*********************************************************************/

typedef struct
{
  uint32_t num_samples;
  uint32_t num_input;
  uint32_t num_output;
  uint32_t input_width;
  uint32_t input_height;
  float **input;
  float **output;
} *dataset_t;

/*********************************************************************/

dataset_t dataset_load(const char* path);

/*********************************************************************/