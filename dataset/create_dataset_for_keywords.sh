#!/bin/bash

set -e

DATASET_SOURCE_DIR="${1}/_human_words_"
DATASET_WANTED_DIR=$2

UNKNWN_WORD=$3
WANTED_WORDS=${@:4}

DATASET_TESTING_FILE="${DATASET_SOURCE_DIR}/testing_list.txt"
DATASET_TRAINING_FILE="${DATASET_SOURCE_DIR}/training_list.txt"
DATASET_VALIDATION_FILE="${DATASET_SOURCE_DIR}/validation_list.txt"

# unknown is virtual directory and shouldn't exist in origin dataset

if [ -d "${DATASET_SOURCE_DIR}/${UNKNWN_WORD}" ]; then
  echo "ASSERT: ${UNKNWN_WORD} conflicts with google dataset"
  exit 1
fi

# clear directory for wanted dataset

rm -rf "${DATASET_WANTED_DIR}"
mkdir "${DATASET_WANTED_DIR}"

# copy wav samples for validation

copy_unknown_wav_samples() {

  local type=$1
  local txt=$2
  local word
  local unknown_cnt
  local wanted_cnt=$3
  local line_cnt=1

  if ((wanted_cnt == 0)); then
    for word in ${WANTED_WORDS} ; do
      local current_count=`grep -c "^${word}/" "${txt}"`
      if ((wanted_cnt == 0 || wanted_cnt > current_count)); then
        wanted_cnt=${current_count}
      fi
    done
  fi

  mkdir "${DATASET_WANTED_DIR}/${type}/${UNKNWN_WORD}"

  while true ; do

    local wav
    local unknown

    for unknown in `awk -F '/' '{ print $(NF-1) }' "${txt}" | sort -u`; do

      for word in ${WANTED_WORDS} ; do
        if [ "${word}" == "${unknown}" ]; then
          continue 2
        fi
      done

      wav=`grep "^${unknown}/.\+0\.wav$" "${txt}" | awk -F '/' -v c="${line_cnt}" 'NR==c { print $NF }'`

      cp "${DATASET_SOURCE_DIR}/${unknown}/${wav}" \
         "${DATASET_WANTED_DIR}/${type}/${UNKNWN_WORD}/${unknown}_${wav}"

      unknown_cnt=$((unknown_cnt+1))
      if ((unknown_cnt == wanted_cnt)); then
        break 2
      fi
    done

    line_cnt=$((line_cnt+1))

  done
}

copy_wanted_wav_samples() {

  local type=$1
  local txt=$2
  local word
  local wanted_cnt=$3

  echo "Copying ${type}..."
  mkdir "${DATASET_WANTED_DIR}/${type}/"

  if ((wanted_cnt == 0)); then
    for word in ${WANTED_WORDS} ; do
      local current_count=`grep -c "^${word}/" "${txt}"`
      if ((wanted_cnt == 0 || wanted_cnt > current_count)); then
        wanted_cnt=${current_count}
      fi
    done
  fi

  for word in ${WANTED_WORDS} ; do
    mkdir "${DATASET_WANTED_DIR}/${type}/${word}"
    local dest="${DATASET_WANTED_DIR}/${type}/${word}"
    grep "^${word}/" "${txt}" | \
    head -n "${wanted_cnt}" | \
    xargs -I{} cp "${DATASET_SOURCE_DIR}/{}" "${dest}"

    if [ -z "$3" ]; then
      local assert_cnt=`find "${dest}" -type f | wc -l`
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

copy_unknown_wav_samples "validation" "${DATASET_VALIDATION_FILE}" 365
copy_unknown_wav_samples "testing" "${DATASET_TESTING_FILE}" 365
copy_unknown_wav_samples "training" "${DATASET_TRAINING_FILE}"

echo "Checking keyword dataset for duplicates..."
if [ ! -z `fdupes . -r "${DATASET_WANTED_DIR}"` ]; then
  echo "ASSERT: duplicates found"
  exit 3
fi