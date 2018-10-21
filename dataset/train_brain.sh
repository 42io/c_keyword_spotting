#!/bin/bash

set -e

DATA_FILE=$1
DATASET_WANTED_DIR=$2
UNKNWN_WORD=$3
WANTED_WORDS=${@:4}

bash ./../src/brain/build.sh

do_confusion_matrix() {
  local model=$1
  local word
  local output_idx
  local wav

  for word in ${WANTED_WORDS} ${UNKNWN_WORD} ; do
    echo -ne "${word}\t| "
    find "${DATASET_WANTED_DIR}/testing/${word}/" "${DATASET_WANTED_DIR}/validation/${word}/" -type f \
      | xargs -I{} sh -c "./../bin/fe {} | ./../bin/guess ./../models/${model}" \
      | awk '{m=$1;j=1;for(i=j;i<=NF;i++)if($i>m){m=$i;j=i;} for(i=1;i<=NF;i++){if(i>1)printf " ";printf "%d", i==j} print ""}' \
      | awk '{for(i=1;i<=NF;i++)sum[i]+=$i} END {for(i in sum){if(i>1)printf " ";printf "%f", sum[i]/NR} print " | " NR}'
  done

  echo "Guessed wrong..."

  for word in ${WANTED_WORDS} ${UNKNWN_WORD} ; do
    output_idx=$((output_idx+1))
    for wav in `find "${DATASET_WANTED_DIR}/testing/${word}/" "${DATASET_WANTED_DIR}/validation/${word}/" -type f `; do
      ./../bin/fe "${wav}" | ./../bin/guess "./../models/${model}" \
       | awk -v x="${output_idx}" -v w="${wav}" '{m=$1;j=1;for(i=j;i<=NF;i++)if($i>m){m=$i;j=i;} if(j!=x)print w}'
    done
  done
}

echo "MLP training..."

rm ./../models/mlp.model
./../bin/mlp_train "${DATA_FILE}"

echo "MLP confusion matrix..."

do_confusion_matrix 'mlp.model'

echo "CNN training..."

rm ./../models/cnn.model
./../bin/cnn_train "${DATA_FILE}"

echo "CNN confusion matrix..."

do_confusion_matrix 'cnn.model'