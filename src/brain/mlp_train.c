#include "kann.h"
#include "dataset.h"
#include <assert.h>
#include "norm.h"

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

static void train(kann_t *ann, dataset_t *ds)
{
  assert(kann_dim_in(ann) == ds->num_input);
  assert(kann_dim_out(ann) == ds->num_output);
  for(int i = 0; i < ds->train.len; i++)
  {
    norm_min_max(ds->train.input[i], ds->num_input);
  }
  kann_train_fnn1(ann, 0.001f, 64, 100, 10, 0.1f,
                  ds->train.len, ds->train.input, ds->train.output);
}

/*********************************************************************/

static void save(kann_t *ann)
{
  kann_save("./../models/mlp.model", ann);
}

/*********************************************************************/

int main(int argc, const char *argv[])
{
  assert(argc == 5);
  dataset_t *ds = dataset_load(argv[1], atol(argv[2]), atol(argv[3]), atol(argv[4]));
  kann_srand(11 /*seed, each train results are reproducible*/);
  kann_t *ann = model_gen(ds->num_input, ds->num_output, KANN_C_CEB, 2, 100);
  assert(!kann_is_rnn(ann));
  train(ann, ds);
  save(ann);
  kann_delete(ann);

  return 0;
}

/*********************************************************************/