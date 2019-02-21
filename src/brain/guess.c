#include "kann.h"
#include <stdlib.h>
#include <assert.h>

/*********************************************************************/

int main(int argc, const char *argv[])
{
  assert(argc == 2);
  kann_t *ann = kann_load(argv[1]);
  assert(ann);

  const int in_num = kann_dim_in(ann);
  float* in = calloc(in_num, sizeof(float*));
  assert(in);
  const float* out = NULL;

  if(kann_is_rnn(ann))
  {
    assert(in_num == 13);
    kann_rnn_start(ann);
    for(int k = 0; k < 49; k++)
    {
      for(int i = 0; i < in_num; i++)
      {
        assert(scanf("%f", &in[i]) == 1);
      }
      assert(getchar() == '\n');
      out = kann_apply1(ann, in);
    }
    assert(getchar() == EOF);
    kann_rnn_end(ann);
  }
  else
  {
    for(int i = 0; i < in_num; i++)
    {
      assert(scanf("%f", &in[i]) == 1);
    }
    assert(getchar() == '\n');
    assert(getchar() == EOF);

    out = kann_apply1(ann, in);
  }

  assert(out);

  for (int i = 0; i < kann_dim_out(ann); i++)
  {
    if (i)
    {
      putchar(' ');
    }
    printf("%f", out[i]);
  }
  putchar('\n');

  kann_delete(ann);
  free(in);

  return 0;
}

/*********************************************************************/