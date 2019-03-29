#!/bin/bash

set -e
set -u

readonly PUB_DOMAIN_SND_DIR=$1
readonly DATASET_WANTED_DIR=$2
readonly PUBLIC_WORD=$3
readonly WANTED_WORDS=${@:4}

readonly PUB_TESTING_FILE="${PUB_DOMAIN_SND_DIR}/testing_list.txt"
readonly PUB_TRAINING_FILE="${PUB_DOMAIN_SND_DIR}/training_list.txt"
readonly PUB_VALIDATION_FILE="${PUB_DOMAIN_SND_DIR}/validation_list.txt"

# public is virtual directory and shouldn't exist in origin dataset

if [ ! -z "`find "${DATASET_WANTED_DIR}" -type d -name "${PUBLIC_WORD}"`" ]; then
  echo "ASSERT: ${PUBLIC_WORD} conflicts with google dataset"
  exit 1
fi

shuf() {
  local filename=$1
  mawk 'BEGIN {srand(42); OFMT="%.17f"} {print rand(), $0}' "$filename" \
    | sort -k1,1n | awk '{print $2}'
}

# copy wav samples

copy_public_wav_samples() {
  local type=$1
  local txt=$2
  local dest="${DATASET_WANTED_DIR}/${type}/${PUBLIC_WORD}"
  local assert_cnt
  local wanted_cnt=${3:-0}

  echo "Copying Public Domain Sounds ${type}..."

  if ((wanted_cnt == 0)); then
    for word in ${WANTED_WORDS} ; do
      wanted_cnt=`find "${DATASET_WANTED_DIR}/${type}/${word}" -type f | wc -l`
      break
    done
  fi

  mkdir "${dest}"

  for wav in `shuf "${txt}" | head -n "${wanted_cnt}"` ; do
    cp "${PUB_DOMAIN_SND_DIR}/${wav}" "${dest}/"
  done

  if [ -z "${3:-}" ]; then
    assert_cnt=`find "${dest}" -type f | wc -l`
    if ((wanted_cnt != assert_cnt)); then
      echo "ASSERT: wanted_cnt(${wanted_cnt}) != assert_cnt(${assert_cnt})"
      exit 2
    fi
  fi
}

copy_public_wav_samples "validation" "${PUB_VALIDATION_FILE}" 365
copy_public_wav_samples "testing" "${PUB_TESTING_FILE}" 365
copy_public_wav_samples "training" "${PUB_TRAINING_FILE}"