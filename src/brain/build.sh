#!/bin/bash

set -e

cd "`dirname "${BASH_SOURCE[0]}"`"

mkdir -p ../../bin

gcc -Werror -Wall -Wextra -Wpedantic -Wno-sign-compare \
  -I. -I../../lib/kann-master \
  -DHAVE_PTHREAD \
  ../../lib/kann-master/kann.c \
  ../../lib/kann-master/kautodiff.c \
  -o ../../bin/mlp_train mlp_train.c dataset.c norm.c -lm -lpthread

echo "MLP train build OK!"

gcc -Werror -Wall -Wextra -Wpedantic -Wno-sign-compare \
  -I. -I../../lib/kann-master \
  -DHAVE_PTHREAD \
  ../../lib/kann-master/kann.c \
  ../../lib/kann-master/kautodiff.c \
  -o ../../bin/cnn_train cnn_train.c dataset.c norm.c -lm -lpthread

echo "CNN train build OK!"

gcc -Werror -Wall -Wextra -Wpedantic -Wno-sign-compare \
  -I. -I../../lib/kann-master \
  -DHAVE_PTHREAD \
  ../../lib/kann-master/kann.c \
  ../../lib/kann-master/kautodiff.c \
  -o ../../bin/rnn_train rnn_train.c dataset.c -lm -lpthread

echo "RNN train build OK!"

gcc -Werror -Wall -Wextra -Wpedantic -Wno-sign-compare \
  -I. -I../../lib/kann-master \
  ../../lib/kann-master/kann.c \
  ../../lib/kann-master/kautodiff.c \
  -o ../../bin/guess guess.c norm.c -lm

echo "Guess build OK!"