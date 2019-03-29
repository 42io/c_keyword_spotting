#!/bin/bash

set -e
set -u

readonly DATASET_SOURCE_DIR="${1}/_human_words_"
readonly DATASET_WANTED_DIR=$2
readonly WANTED_WORDS=${@:3}

readonly DATASET_TESTING_FILE="${DATASET_SOURCE_DIR}/testing_list.txt"
readonly DATASET_TRAINING_FILE="${DATASET_SOURCE_DIR}/training_list.txt"
readonly DATASET_VALIDATION_FILE="${DATASET_SOURCE_DIR}/validation_list.txt"

# clear directory for wanted dataset

rm -rf "${DATASET_WANTED_DIR}"
mkdir "${DATASET_WANTED_DIR}"

shuf() {
  mawk 'BEGIN {srand(42); OFMT="%.17f"} {print rand(), $0}' \
    | sort -k1,1n | awk '{print $2}'
}

copy_wanted_wav_samples() {
  local type=$1
  local txt=$2
  local word
  local dest
  local assert_cnt
  local current_count
  local wanted_cnt=${3:-0}

  echo "Copying Wanted Words ${type}..."

  for word in ${WANTED_WORDS} ; do
    if [ ! -d "${DATASET_SOURCE_DIR}/${word}" ]; then
      echo "ASSERT: no such word ${word}"
      exit 1
    fi
  done

  mkdir "${DATASET_WANTED_DIR}/${type}/"

  if ((wanted_cnt == 0)); then
    for word in ${WANTED_WORDS} ; do
      current_count=`grep -c "^${word}/" "${txt}"`
      if ((wanted_cnt == 0 || wanted_cnt > current_count)); then
        wanted_cnt=${current_count}
      fi
    done
  fi

  for word in ${WANTED_WORDS} ; do
    dest="${DATASET_WANTED_DIR}/${type}/${word}"
    mkdir "${dest}"
    grep "^${word}/" "${txt}" \
      | shuf \
      | head -n "${wanted_cnt}" \
      | xargs -I{} cp "${DATASET_SOURCE_DIR}/{}" "${dest}"

    if [ -z "${3:-}" ]; then
      assert_cnt=`find "${dest}" -type f | wc -l`
      if ((wanted_cnt != assert_cnt)); then
        echo "ASSERT: wanted_cnt(${wanted_cnt}) != assert_cnt(${assert_cnt})"
        exit 2
      fi
    fi
  done
}

copy_wanted_wav_samples "validation" "${DATASET_VALIDATION_FILE}" 365
copy_wanted_wav_samples "testing" "${DATASET_TESTING_FILE}" 365
copy_wanted_wav_samples "training" "${DATASET_TRAINING_FILE}"