#!/bin/bash

set -e

DATA_FILE=$1
DATASET_WANTED_DIR=$2
UNKNWN_WORD=$3
WANTED_WORDS=${@:4}

for word in ${WANTED_WORDS} ${UNKNWN_WORD} ; do
  output_num=$((output_num+1))
done

bash ./../src/features/build.sh

echo -n `find ${DATASET_WANTED_DIR}/training/ -type f | wc -l` > "${DATA_FILE}"
echo -n ' ' >> "${DATA_FILE}"
echo -n `find ${DATASET_WANTED_DIR}/training/ -type f | head -n 1 | xargs ./../bin/fe | tr ' ' '\n' | wc -l` >> "${DATA_FILE}"
echo -n ' ' >> "${DATA_FILE}"
echo "${output_num}" >> "${DATA_FILE}"

out_to_vec() {
  local num=$1
  local idx=$2
  local i
  for i in `seq 1 ${num}`; do
    if ((i != 1)); then
      echo -n ' ' >> "${DATA_FILE}"
    fi
    if ((i == idx))
    then
      echo -n '1' >> "${DATA_FILE}"
    else
      echo -n '0' >> "${DATA_FILE}"
    fi
  done
  echo >> "${DATA_FILE}"
}

echo "Extracting features..."

for word in ${WANTED_WORDS} ${UNKNWN_WORD} ; do
  output_idx=$((output_idx+1))
  for wav in `find "${DATASET_WANTED_DIR}/training/${word}/" -type f | sort`; do
    ./../bin/fe "${wav}" >> "${DATA_FILE}"
    out_to_vec "${output_num}" "${output_idx}"
  done
done
