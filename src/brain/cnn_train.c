#include "kann.h"
#include "dataset.h"
#include <assert.h>

/*********************************************************************/

static kann_t *model_gen(int height, int width, int n_out, int n_h_fc, int n_h_flt, float dropout)
{
    kad_node_t *t;
    t = kad_feed(4, 1, 1, height, width), t->ext_flag |= KANN_F_IN;
    t = kad_relu(kann_layer_conv2d(t, n_h_flt, 3, 3, 1, 1, 0, 0)); // 3x3 kernel; 1x1 stride; 0x0 padding
    t = kad_relu(kann_layer_conv2d(t, n_h_flt, 3, 3, 1, 1, 0, 0));
    t = kad_max2d(t, 2, 2, 2, 2, 0, 0); // 2x2 kernel; 2x2 stride; 0x0 padding
    t = kann_layer_dropout(t, dropout);
    t = kann_layer_dense(t, n_h_fc);
    t = kad_relu(t);
    t = kann_layer_dropout(t, dropout);
    return kann_new(kann_layer_cost(t, n_out, KANN_C_CEB), 0);
}

/*********************************************************************/

static void train(kann_t *ann, dataset_t data)
{
  assert(kann_dim_in(ann) == data->num_input);
  assert(kann_dim_out(ann) == data->num_output);
  kann_train_fnn1(ann, 0.001f, 64, 100, 10, 0.1f,
                  data->num_samples, data->input, data->output);
}

/*********************************************************************/

static void save(kann_t *ann)
{
  kann_save("./../models/cnn.model", ann);
}

/*********************************************************************/

int main(int argc, const char *argv[])
{
  dataset_t data = dataset_load(argc > 1 ? argv[1] : NULL);
  kann_srand(131 /*seed, each train results are reproducible*/);
  kann_t *ann = model_gen(data->input_height, data->input_width, data->num_output, 128, 32, 0.2f);
  train(ann, data);
  save(ann);
  kann_delete(ann);

  return 0;
}

/*********************************************************************/