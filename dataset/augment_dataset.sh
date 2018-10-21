#!/bin/bash

set -e

DATASET_NOISE_DIR="${1}/_background_noise_"
DATASET_WANTED_DIR=$2
UNKNWN_WORD=$3
WANTED_WORDS=${@:4}

echo "Augmentation..."

for word in ${WANTED_WORDS} ${UNKNWN_WORD} ; do
  for wav in `find "${DATASET_WANTED_DIR}/training/${word}/" -type f`; do
    sox -v 0.4 -R "${wav}" "${wav%.*}_a1.wav" pitch -50
    sox -v 0.2 -R "${wav}" "${wav%.*}_a2.wav" pitch 50
    sox -v 0.3 -R "${wav}" "${wav%.*}_a3.wav" pitch -150
    sox -v 0.5 -R "${wav}" "${wav%.*}_a4.wav" pitch 150
    cursor=$((cursor+1))
    noise=`find "${DATASET_NOISE_DIR}" -name '*.wav' | awk -v c="${cursor}" '{rows[NR]=$0};END{c=(c-1)%NR; print rows[c+1]}'`
    sox -R --norm "${noise}" -p | sox -m -v 0.6 -R "${wav}" -v 0.01 -R -p "${wav%.*}_a5.wav"
  done
done
