#include "kann.h"
#include "dataset.h"
#include <assert.h>

/*********************************************************************/

static kann_t *model_gen(int n_in, int n_out, int loss_type, int n_h_layers, int n_h_neurons)
{
  int i;
  kad_node_t *t;
  t = kann_layer_input(n_in);
  for (i = 0; i < n_h_layers; ++i)
    t = kad_relu(kann_layer_dense(t, n_h_neurons));
  return kann_new(kann_layer_cost(t, n_out, loss_type), 0);
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
  kann_save("./../models/mlp.model", ann);
}

/*********************************************************************/

int main(int argc, const char *argv[])
{
  dataset_t data = dataset_load(argc > 1 ? argv[1] : NULL);
  kann_srand(11 /*seed, each train results are reproducible*/);
  kann_t *ann = model_gen(data->num_input, data->num_output, KANN_C_CEB, 2, 100);
  train(ann, data);
  save(ann);
  kann_delete(ann);

  return 0;
}

/*********************************************************************/