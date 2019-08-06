#!/bin/bash

set -e
set -u

cd "`dirname "${BASH_SOURCE[0]}"`"

export LC_ALL=C

readonly DATASET_FILE_NAME=$1
readonly DATASET_NUM_OUTPUT=$4

bash ./../src/brain/build.sh

do_confusion_matrix() {
  local model=$1
  local i
  for i in `seq ${DATASET_NUM_OUTPUT}` ; do
    awk -v m="${DATASET_NUM_OUTPUT}" '$1 >= m' "${DATASET_FILE_NAME}" \
      | awk -v i="${i}" -v m="${DATASET_NUM_OUTPUT}" '$1 == i - 1 + m || $1 == i - 1 + 2*m' \
      | awk '{for(i=2;i<=NF;i++){if(i>2)printf " ";printf $i} print ""}' \
      | ./../bin/guess "./../models/${model}" \
      | awk '{m=$1;j=1;for(i=j;i<=NF;i++)if($i>m){m=$i;j=i;} for(i=1;i<=NF;i++){if(i>1)printf " ";printf "%d", i==j} print ""}' \
      | awk '{for(i=1;i<=NF;i++)sum[i]+=$i} END {for(j=1;j<i;j++){if(j>1)printf " ";printf "%.2f", sum[j]/NR} print " | " NR}'
  done
}

do_validation() {
  local model=$1
  local i
  for i in `seq ${DATASET_NUM_OUTPUT}` ; do
    awk -v m="${DATASET_NUM_OUTPUT}" '$1 >= m' "${DATASET_FILE_NAME}" \
      | awk -v i="${i}" -v m="${DATASET_NUM_OUTPUT}" '$1 == i - 1 + m || $1 == i - 1 + 2*m' \
      | awk '{for(i=2;i<=NF;i++){if(i>2)printf " ";printf $i} print ""}' \
      | ./../bin/guess "./../models/${model}" \
      | awk -v x="${i}" '{m=$1;j=1;for(i=j;i<=NF;i++)if($i>m){m=$i;j=i;} if(j!=x)print x}'
  done
}

leave_only_the_best_model() {
  local pattern="./../models/${1}"
  local best_model="./../models/${2}"
  local best_score
  local best_score_has_value=
  local score
  local model

  rm "${best_model}"

  for model in `ls -tr ${pattern}`
  do
    score=`do_validation "${model}" | wc -l`
    echo "${model} ${score}"
    if ((best_score_has_value == 0 || best_score > score)); then
      best_score_has_value=1
      best_score=${score}
      cp "${model}" "${best_model}"
    fi
  done
  echo "Best model score is ${best_score}"
  rm ${pattern}
}

echo 'MLP training...'
rm ./../models/mlp.model
./../bin/mlp_train "${@}"
echo 'MLP confusion matrix...'
do_confusion_matrix 'mlp.model'
echo "MLP guessed wrong `do_validation 'mlp.model' | wc -l`..."

echo 'CNN training...'
rm ./../models/cnn.model
./../bin/cnn_train "${@}"
echo 'CNN confusion matrix...'
do_confusion_matrix 'cnn.model'
echo "CNN guessed wrong `do_validation 'cnn.model' | wc -l`..."

echo 'RNN training...'
rm -f ./../models/rnn-epoch-*.model
./../bin/rnn_train "${@}"
leave_only_the_best_model 'rnn-epoch-*.model' 'rnn.model'
echo 'RNN confusion matrix...'
do_confusion_matrix 'rnn.model'
echo "RNN guessed wrong `do_validation 'rnn.model' | wc -l`..."