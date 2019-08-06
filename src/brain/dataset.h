#pragma once

#include <stdint.h>

/*********************************************************************/

typedef struct
{
  uint32_t len;
  float **input;
  float **output;
} dataset_array_t;

/*********************************************************************/

typedef struct
{
  uint32_t num_input;
  uint32_t num_output;
  uint32_t input_width;
  uint32_t input_height;
  dataset_array_t train, valid, test;
} dataset_t;

/*********************************************************************/

dataset_t* dataset_load(
  const char* const path,
  const uint32_t input_height,
  const uint32_t input_width,
  const uint32_t num_output);

/*********************************************************************/