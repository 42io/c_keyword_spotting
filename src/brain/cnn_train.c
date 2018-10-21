#include "kann.h"
#include "dataset.h"
#include <assert.h>

/*********************************************************************/

static kann_t *model_gen(int height, int width, int n_out, int n_h_fc, float dropout)
{
  assert(height == 49);
  assert(width == 13);
  kad_node_t *t;
  t = kad_feed(4, 1, 1, height, width), t->ext_flag |= KANN_F_IN;
  t = kad_relu(kann_layer_conv2d(t, 32, 13, 8, 1, 1, 0, 0)); // 13x8 kernel; 1x1 stride; 0x0 padding
  // output height = ((H-F+2*P)/S)+1
  // output height = H(input height), F(filter height), P(padding height), S(stride height)
  // output height = 49 - 13 + 1 = 37
  // output width  = 13 - 8 + 1 = 6
  t = kad_relu(kann_layer_conv2d(t, 64, 8, 6, 1, 1, 0, 0));
  // output height = 37 - 8 + 1 = 30
  // output width  = 6 - 6 + 1 = 1
  t = kann_layer_dropout(t, dropout);
  t = kad_max2d(t, 2, 1, 2, 1, 0, 0); // 2x1 kernel; 2x1 stride; 0x0 padding
  // output height = 30/2 = 15
  // output width  = 1/1 = 1
  t = kad_relu(kann_layer_dense(t, n_h_fc));
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
  kann_t *ann = model_gen(data->input_height, data->input_width, data->num_output, 128, 0.2f);
  train(ann, data);
  save(ann);
  kann_delete(ann);

  return 0;
}

/*********************************************************************/