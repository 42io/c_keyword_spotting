#!/bin/bash

set -e
set -u

readonly DATASET_NOISE_DIR="${1}/_background_noise_"
readonly DATASET_WANTED_DIR=$2
readonly WANTED_WORDS=${@:3}
readonly DATASET_NOISE_FILE="${DATASET_NOISE_DIR}/noise_list.txt"

declare -i cursor=0

check_dataset_md5() {
  local expected=$1
  local src=${2:-${DATASET_WANTED_DIR}}
  local md5
  echo "Checking md5 ${src}..."
  md5=`cd "${src}" && find . -type f -print0 | sort -z | xargs -0 md5sum | md5sum | awk '{ print $1 }'`
  if [ "${expected}" != "${md5}" ]; then
    echo "ASSERT: md5 mismatch ${expected} != ${md5}"
    exit 1
  fi
}

words_from_demo() {
  if [ 'zeroonetwothreefourfivesixseveneightnine' == "${WANTED_WORDS//[[:blank:]]/}" ]
  then
    return 1
  fi
  return 0
}

shuf() {
  local filename=$1
  mawk 'BEGIN {srand(42); OFMT="%.17f"} {print rand(), $0}' "$filename" \
    | sort -k1,1n | awk '{print $2}'
}

mix_noise() {
  local vi=$1
  local vo=$2
  local in=$3
  local out=$4
  local noise
  cursor+=1
  noise=`shuf "${DATASET_NOISE_FILE}" \
    | awk -v c="${cursor}" '{rows[NR]=$0};END{c=(c-1)%NR; print rows[c+1]}'`
  sox -R --norm "${DATASET_NOISE_DIR}/${noise}" -p \
    | sox -R -m -v "${vi}" "${in}" -v "${vo}" -p "${out}"
}

words_from_demo || check_dataset_md5 '8640d2885ff5ff7087000e194bc9c3a7'

for word in ${WANTED_WORDS} ; do
  echo "Augmentation ${word}..."
  for wav in `find "${DATASET_WANTED_DIR}/training/${word}/" -type f | sort`; do
    sox -R -v 0.7 "${wav}" "${wav%.*}_a1.wav" pitch -50
    sox -R -v 0.5 "${wav}" "${wav%.*}_a2.wav" pitch 50
    sox -R -v 0.4 "${wav}" "${wav%.*}_a3.wav" pitch -150
    sox -R -v 0.2 "${wav}" "${wav%.*}_a4.wav" pitch 150
    mix_noise '0.8' '0.02'  "${wav}" "${wav%.*}_a6.wav"
    mix_noise '0.6' '0.015' "${wav}" "${wav%.*}_a7.wav"
    mix_noise '0.3' '0.01'  "${wav}" "${wav%.*}_a8.wav"
  done
done

words_from_demo || check_dataset_md5 'f967ab8afb7e524c49b49f45fcd8ba18'