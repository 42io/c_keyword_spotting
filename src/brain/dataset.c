#include "dataset.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

/*********************************************************************/

static dataset_t dataset_create(uint32_t num_samples, uint32_t num_input, uint32_t num_output)
{
  dataset_t data = calloc(1, sizeof(*data));
  assert(data);

  data->input_height = 0;
  data->input_width = 0;
  data->num_samples = num_samples;
  data->num_input = num_input;
  data->num_output = num_output;

  data->input = calloc(num_samples, sizeof(float*));
  assert(data->input);

  data->output = calloc(num_samples, sizeof(float*));
  assert(data->output);

  for (int i = 0; i < num_samples; i++)
  {
    data->input[i] = calloc(num_input, sizeof(float));
    data->output[i] = calloc(num_output, sizeof(float));
    assert(data->input[i]);
    assert(data->output[i]);
  }

  return data;
}

/*********************************************************************/

static dataset_t dataset_from_fd(FILE *fd)
{
  uint32_t num_input, num_output, num_samples, i, j;
  dataset_t data;

  assert(fscanf(fd, "%u %u %u", &num_samples, &num_input, &num_output) == 3);
  assert(fgetc(fd) == '\n');

  data = dataset_create(num_samples, num_input, num_output);

  for(i = 0; i != num_samples; i++)
  {
    for(j = 0; j != num_input; j++)
    {
      assert(fscanf(fd, "%f", &data->input[i][j]) == 1);
      if(i == 0)
      {
        const int c = fgetc(fd);
        if(c == '\n')
        {
          data->input_height++;
        }
        ungetc(c, fd);
      }
    }
    assert(fgetc(fd) == '\n');

    for(j = 0; j != num_output; j++)
    {
      assert(fscanf(fd, "%f", &data->output[i][j]) == 1);
      assert(data->output[i][j] == 0 || data->output[i][j] == 1);
    }
    assert(fgetc(fd) == '\n');
  }

  assert(fgetc(fd) == EOF);

  assert(data->num_input % data->input_height == 0);
  data->input_width = data->num_input / data->input_height;

  return data;
}

/*********************************************************************/

dataset_t dataset_load(const char* path)
{
  dataset_t data;
  FILE *fd = path && strcmp(path, "-") ? fopen(path, "r") : stdin;
  assert(fd);

  data = dataset_from_fd(fd);

  if(fd != stdin)
  {
    fclose(fd);
  }

  return data;
}

/*********************************************************************/