#!/bin/bash

set -e
set -u

readonly DATA_FILE=$1
readonly DATASET_WANTED_DIR=$2
readonly UNKNWN_WORD=$3
readonly PUBLIC_WORD=$4
readonly WANTED_WORDS=${@:5}

bash ./../src/brain/build.sh

do_confusion_matrix() {
  local model=$1
  local word

  for word in ${WANTED_WORDS} ${UNKNWN_WORD} ${PUBLIC_WORD} ; do
    echo -ne "${word}\t| "
    find "${DATASET_WANTED_DIR}/testing/${word}/" "${DATASET_WANTED_DIR}/validation/${word}/" -type f \
      | xargs -I{} sh -c "./../bin/fe '{}' | ./../bin/guess ./../models/${model}" \
      | awk '{m=$1;j=1;for(i=j;i<=NF;i++)if($i>m){m=$i;j=i;} for(i=1;i<=NF;i++){if(i>1)printf " ";printf "%d", i==j} print ""}' \
      | awk '{for(i=1;i<=NF;i++)sum[i]+=$i} END {for(j=1;j<i;j++){if(j>1)printf " ";printf "%.2f", sum[j]/NR} print " | " NR}'
  done
}

do_validation() {
  local model=$1
  local word
  local -i output_idx=
  local wav

  for word in ${WANTED_WORDS} ${UNKNWN_WORD} ${PUBLIC_WORD} ; do
    output_idx+=1
    for wav in `find "${DATASET_WANTED_DIR}/testing/${word}/" "${DATASET_WANTED_DIR}/validation/${word}/" -type f `; do
      ./../bin/fe "${wav}" | ./../bin/guess "./../models/${model}" \
       | awk -v x="${output_idx}" -v w="${wav}" '{m=$1;j=1;for(i=j;i<=NF;i++)if($i>m){m=$i;j=i;} if(j!=x)print w}'
    done
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
./../bin/mlp_train "${DATA_FILE}"
echo 'MLP confusion matrix...'
do_confusion_matrix 'mlp.model'
echo "MLP guessed wrong `do_validation 'mlp.model' | wc -l`..."
do_validation 'mlp.model'

echo 'CNN training...'
rm ./../models/cnn.model
./../bin/cnn_train "${DATA_FILE}"
echo 'CNN confusion matrix...'
do_confusion_matrix 'cnn.model'
echo "CNN guessed wrong `do_validation 'cnn.model' | wc -l`..."
do_validation 'cnn.model'

echo 'RNN training...'
rm -f ./../models/rnn-epoch-*.model
./../bin/rnn_train "${DATA_FILE}"
leave_only_the_best_model 'rnn-epoch-*.model' 'rnn.model'
echo 'RNN confusion matrix...'
do_confusion_matrix 'rnn.model'
echo "RNN guessed wrong `do_validation 'rnn.model' | wc -l`..."
do_validation 'rnn.model'