#include "dataset.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

/*********************************************************************/

static dataset_t* dataset_from_fd(
  FILE *fd,
  const uint32_t input_height,
  const uint32_t input_width,
  const uint32_t num_output)
{
  dataset_t *ds = malloc(sizeof(*ds));
  assert(ds);

  ds->train.input  = ds->valid.input  = ds->test.input  = NULL;
  ds->train.output = ds->valid.output = ds->test.output = NULL;
  ds->train.len    = ds->valid.len    = ds->test.len    = 0;
  ds->input_width  = input_width;
  ds->input_height = input_height;
  ds->num_output   = num_output;
  ds->num_input    = input_width * input_height;

  int32_t output_val = 0;
  while(fscanf(fd, "%d", &output_val) == 1)
  {
    dataset_array_t *dest;
    if(output_val < num_output)
    {
      dest = &ds->train;
    }
    else if(output_val < 2 * num_output)
    {
      output_val -= num_output;
      dest = &ds->valid;
    }
    else
    {
      output_val -= 2 * num_output;
      dest = &ds->test;
    }

    assert(output_val < num_output);

    uint32_t i = dest->len++;

    dest->output = realloc(dest->output, dest->len * sizeof(float*));
    assert(dest->output);
    dest->output[i] = malloc(num_output * sizeof(float));
    for(int j = 0; j < num_output; j++)
    {
      dest->output[i][j] = j == output_val ? 1 : 0;
    }

    dest->input = realloc(dest->input, dest->len * sizeof(float*));
    assert(dest->input);
    dest->input[i] = malloc(ds->num_input * sizeof(float));
    for(int j = 0; j < ds->num_input; j++)
    {
      assert(fscanf(fd, "%f", &dest->input[i][j]) == 1);
    }
    assert(fgetc(fd) == '\n');
  }

  assert(fgetc(fd) == EOF);

  return ds;
}

/*********************************************************************/

dataset_t* dataset_load(
  const char* const path,
  const uint32_t input_height,
  const uint32_t input_width,
  const uint32_t num_output)
{
  FILE *fd = path && strcmp(path, "-") ? fopen(path, "r") : stdin;
  assert(fd);

  dataset_t* ds = dataset_from_fd(fd, input_height, input_width, num_output);

  if(fd != stdin)
  {
    fclose(fd);
  }

  printf("Dataset train %u, valid %u, test %u\n",
          ds->train.len, ds->valid.len, ds->test.len);

  assert(ds->train.output[0][0] == 1);
  assert(ds->valid.output[0][0] == 1);
  assert(ds->test.output[0][0]  == 1);
  assert(ds->train.output[0][num_output - 1] == 0);
  assert(ds->valid.output[0][num_output - 1] == 0);
  assert(ds->test.output[0][num_output  - 1] == 0);

  assert(ds->train.output[ds->train.len - 1][num_output - 1] == 1);
  assert(ds->valid.output[ds->valid.len - 1][num_output - 1] == 1);
  assert(ds->test.output[ds->test.len   - 1][num_output - 1] == 1);
  assert(ds->train.output[ds->train.len - 1][0] == 0);
  assert(ds->valid.output[ds->valid.len - 1][0] == 0);
  assert(ds->test.output[ds->test.len   - 1][0] == 0);

  return ds;
}

/*********************************************************************/