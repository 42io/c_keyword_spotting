#include "kann.h"
#include "dataset.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>

/*********************************************************************/

static kann_t *model_gen(int n_in, int n_out, int n_h_layers, int n_h_neurons, float dropout)
{
  int i;
  kad_node_t *t;
  int rnn_flag = KANN_RNN_VAR_H0 | KANN_RNN_NORM;
  t = kann_layer_input(n_in);
  for (i = 0; i < n_h_layers; ++i) {
    t = kann_layer_gru(t, n_h_neurons, rnn_flag);
    t = kann_layer_dropout(t, dropout);
  }
  t = kad_select(1, &t, -1);
  return kann_new(kann_layer_cost(t, n_out, KANN_C_CEB), 0);
}

/*********************************************************************/

static void train(kann_t *ann, dataset_t *ds, float lr, int mini_size, int max_epoch, const char *fn, int n_threads)
{
  float **x, **y, *r, best_cost = 1e30f;
  int epoch, j, n_var, *shuf, ulen = ds->input_height, n_in = ds->input_width, n_out = ds->num_output;
  dataset_array_t *d = &ds->train;
  kann_t *ua;

  assert(kann_dim_in(ann) == n_in);
  assert(kann_dim_out(ann) == n_out);

  assert(ulen == 49);
  assert(n_in == 13);

  n_var = kann_size_var(ann);
  r = (float*)calloc(n_var, sizeof(float));
  x = (float**)malloc(ulen * sizeof(float*));
  y = (float**)malloc(1 * sizeof(float*));
  for (j = 0; j < ulen; ++j) {
    x[j] = (float*)calloc(mini_size * n_in, sizeof(float));
  }
  y[0] = (float*)calloc(mini_size * n_out, sizeof(float));
  shuf = (int*)calloc(d->len, sizeof(int));

  ua = kann_unroll(ann, ulen);
  kann_set_batch_size(ua, mini_size);
  kann_mt(ua, n_threads, mini_size);
  kann_feed_bind(ua, KANN_F_IN,    0, x);
  kann_feed_bind(ua, KANN_F_TRUTH, 0, y);
  kann_switch(ua, 1);
  for (epoch = 0; epoch < max_epoch; ++epoch) {
    kann_shuffle(d->len, shuf);
    double cost = 0.0;
    int tot = 0, tot_base = 0, n_cerr = 0;
    for (j = 0; j < d->len - mini_size; j += mini_size) {
      int b, k;
      for (b = 0; b < mini_size; ++b) {
        int s = shuf[j + b];
        for (k = 0; k < ulen; ++k) {
          memcpy(&x[k][b * n_in], &d->input[s][k * n_in], n_in * sizeof(float));
        }
        memcpy(&y[0][b * n_out], d->output[s], n_out * sizeof(float));
      }
      cost += kann_cost(ua, 0, 1) * ulen * mini_size;
      n_cerr += kann_class_error(ua, &k);
      tot_base += k;
      //kad_check_grad(ua->n, ua->v, ua->n-1);
      kann_RMSprop(n_var, lr, 0, 0.9f, ua->g, ua->x, r);
      tot += ulen * mini_size;
    }
    if (cost < best_cost) {
      best_cost = cost;
      if (fn) {
        const size_t len = snprintf(NULL, 0, fn, epoch+1);
        assert(len > 0);
        char *fn_ws_epoch = malloc((len+1) * sizeof(char));
        assert(fn_ws_epoch);
        assert(snprintf(fn_ws_epoch, len+1, fn, epoch+1) == len);
        kann_save(fn_ws_epoch, ann);
        free(fn_ws_epoch);
      }
    }
    fprintf(stderr, "epoch: %d; cost: %g (class error: %.2f%%)\n", epoch+1, cost / tot, 100.0f * n_cerr / tot_base);
  }

  kann_delete_unrolled(ua);

  for (j = 0; j < ulen; ++j) {
    free(x[j]);
  }
  free(y[0]); free(y); free(x); free(r); free(shuf);
}

/*********************************************************************/

int main(int argc, const char *argv[])
{
  assert(argc == 5);
  dataset_t *ds = dataset_load(argv[1], atol(argv[2]), atol(argv[3]), atol(argv[4]));

  int mini_size = 64, max_epoch = 500, seed = 84, n_h_layers = 3, n_h_neurons = 32, n_threads = 1;
  float lr = 0.001f, dropout = 0.2f;

  kann_srand(seed /*seed, each train results are reproducible*/);
  kann_t *ann = model_gen(ds->input_width, ds->num_output, n_h_layers, n_h_neurons, dropout);
  assert(kann_is_rnn(ann));

  train(ann, ds, lr, mini_size, max_epoch, "./../models/rnn-epoch-%d.model", n_threads);
  kann_delete(ann);

  return 0;
}

/*********************************************************************/
