#pragma once

#include "c_speech_features_config.h"

/*********************************************************************/

csf_float* fe_mfcc_16k_16b_mono(short *aBuffer, int aBufferSize,
                                int* n_frames, int* n_items_in_frame);

csf_float* fe_fbank_16k_16b_mono(short *aBuffer, int aBufferSize,
                                 int* n_frames, int* n_items_in_frame);

/*********************************************************************/