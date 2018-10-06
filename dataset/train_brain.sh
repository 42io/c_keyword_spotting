#!/bin/bash

set -e

DATA_FILE=$1
DATASET_WANTED_DIR=$2
UNKNWN_WORD=$3
WANTED_WORDS=${@:4}

bash ./../src/brain/build.sh

echo "MLP training..."

rm ./../models/mlp.model
./../bin/mlp_train "${DATA_FILE}"

echo "MLP confusion matrix..."

for word in ${WANTED_WORDS} ${UNKNWN_WORD} ; do
  echo -ne "${word}\t| "
  find "${DATASET_WANTED_DIR}/testing/${word}/" "${DATASET_WANTED_DIR}/validation/${word}/" -type f \
    | xargs -I{} sh -c './../bin/fe {} | ./../bin/guess ./../models/mlp.model' \
    | awk '{m=$1;j=1;for(i=j;i<=NF;i++)if($i>m){m=$i;j=i;} for(i=1;i<=NF;i++){if(i>1)printf " ";printf "%d", i==j} print ""}' \
    | awk '{for(i=1;i<=NF;i++)sum[i]+=$i} END {for (i=1;i<=NF;i++){if(i>1)printf " ";printf "%f", sum[i]/NR} print " | " NR}'
done

echo "CNN training..."

rm ./../models/cnn.model
./../bin/cnn_train "${DATA_FILE}"

echo "CNN confusion matrix..."

for word in ${WANTED_WORDS} ${UNKNWN_WORD} ; do
  echo -ne "${word}\t| "
  find "${DATASET_WANTED_DIR}/testing/${word}/" "${DATASET_WANTED_DIR}/validation/${word}/" -type f \
    | xargs -I{} sh -c './../bin/fe {} | ./../bin/guess ./../models/cnn.model' \
    | awk '{m=$1;j=1;for(i=j;i<=NF;i++)if($i>m){m=$i;j=i;} for(i=1;i<=NF;i++){if(i>1)printf " ";printf "%d", i==j} print ""}' \
    | awk '{for(i=1;i<=NF;i++)sum[i]+=$i} END {for (i=1;i<=NF;i++){if(i>1)printf " ";printf "%f", sum[i]/NR} print " | " NR}'
done