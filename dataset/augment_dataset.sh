#!/bin/bash

set -e

DATASET_WANTED_DIR=$1
UNKNWN_WORD=$2
WANTED_WORDS=${@:3}

echo "Augmentation..."

for word in ${WANTED_WORDS} ${UNKNWN_WORD} ; do
  for wav in `find "${DATASET_WANTED_DIR}/training/${word}/" -type f`; do
    sox -v 0.5 -R "${wav}" "${wav%.*}_a1.wav"
    sox -v 0.3 -R "${wav}" "${wav%.*}_a2.wav"
    sox -v 0.4 -R "${wav}" "${wav%.*}_a3.wav" pitch -150
    sox -v 0.6 -R "${wav}" "${wav%.*}_a4.wav" pitch 150
  done
done
