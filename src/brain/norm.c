#include "norm.h"

/*********************************************************************/

void norm_min_max(float* const samples, const size_t n_samples)
{
  float max, min;

  if(n_samples < 1)
  {
    return;
  }

  for(size_t i = 0; i < n_samples; i++)
  {
    const float sample = samples[i];
    if(i)
    {
      if(sample > max)
      {
         max = sample;
      }
      if(sample < min)
      {
        min = sample;
      }
    }
    else
    {
      max = min = sample;
    }
  }

  if(max - min == 0)
  {
    for(size_t i = 0; i < n_samples; i++)
    {
      samples[i] = 1;
    }
  }
  else
  {
    for(size_t i = 0; i < n_samples; i++)
    {
      samples[i] = (samples[i] - min) / (max - min);
    }
  }
}

/*********************************************************************/