#include "fe.h"
#include "c_speech_features.h"
#include <stddef.h>
#include <stdbool.h>

/*********************************************************************/

#define SAMPLE_RATE   16000
#define WIN_LEN       0.05f
#define WIN_STEP      0.02f
#define NUM_CEP       13
#define NUM_FILTERS   26
#define NUM_FFT       1024
#define LOWFREQ       0
#define HIGHFRWQ      SAMPLE_RATE/2
#define PREEMPH       0.97f
#define CEP_LIFTER    22
#define APPEND_ENERGY true

/*********************************************************************/

static void min_max_norm(csf_float* const samples, const size_t n_samples)
{
  csf_float max, min;

  if(n_samples < 1)
  {
    return;
  }

  for(size_t i = 0; i < n_samples; i++)
  {
    const csf_float sample = samples[i];
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

csf_float* fe_mfcc_16k_16b_mono(short *aBuffer, int aBufferSize, int* n_frames, int* n_items_in_frame)
{
  csf_float* mfcc = NULL;
  *n_items_in_frame = NUM_CEP;
  *n_frames = csf_mfcc(aBuffer, aBufferSize,
                       SAMPLE_RATE, WIN_LEN, WIN_STEP, NUM_CEP,
                       NUM_FILTERS, NUM_FFT, LOWFREQ, HIGHFRWQ, PREEMPH,
                       CEP_LIFTER, APPEND_ENERGY,
                       NULL, &mfcc);

  if(mfcc)
  {
    min_max_norm(mfcc, *n_frames**n_items_in_frame);
  }

  return mfcc;
}

/*********************************************************************/

csf_float* fe_fbank_16k_16b_mono(short *aBuffer, int aBufferSize, int* n_frames, int* n_items_in_frame)
{
  csf_float* feat = NULL;
  *n_items_in_frame = NUM_FILTERS;
  *n_frames = csf_fbank(aBuffer, aBufferSize,
                       SAMPLE_RATE, WIN_LEN, WIN_STEP,
                       NUM_FILTERS, NUM_FFT, LOWFREQ, HIGHFRWQ, PREEMPH,
                       NULL, &feat, NULL);

  if(feat)
  {
    min_max_norm(feat, *n_frames**n_items_in_frame);
  }

  return feat;
}

/*********************************************************************/