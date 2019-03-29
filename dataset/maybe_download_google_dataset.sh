#!/bin/bash

set -e
set -u

readonly DATASET_DIR=$1
readonly HUMAN_WORDS_DIR="${DATASET_DIR}/_human_words_"
readonly HTTP_URL='http://download.tensorflow.org/data/speech_commands_v0.02.tar.gz'

readonly DATASET_NOISE_DIR="${DATASET_DIR}/_background_noise_"
readonly DATASET_NOISE_FILE="${DATASET_NOISE_DIR}/noise_list.txt"
readonly DATASET_TESTING_FILE='testing_list.txt'
readonly DATASET_TRAINING_FILE='training_list.txt'
readonly DATASET_VALIDATION_FILE='validation_list.txt'

readonly THRESHOLD_RMS=2000     # wav filter
readonly THRESHOLD_VOICE=5000   # wav filter
readonly PADDING_IN_SECONDS=0.1 # wav filter

# functions

wav_size_ok() {
  local wav_size_in_frames=`sox --info -s "${1}"`
  if ((wav_size_in_frames != 16000)); then
    echo "Suspicious size: ${wav_size_in_frames} ${1}"
    return 1
  fi
  return 0
}

wav_right_padded() {
  local rms_end=`sox "${1}" -p trim "-${PADDING_IN_SECONDS}" | \
                 sox -p -n stat 2>&1 | \
                 awk '/RMS[ \t\n]+amplitude:/ { print int($3*32768) }'`
  if ((rms_end > THRESHOLD_RMS)); then
    echo "Suspicious end RMS:${rms_end} ${1}"
    return 1
  fi
}

wav_left_padded() {
  local rms_start=`sox "${1}" -p trim 0 "${PADDING_IN_SECONDS}" | \
                   sox -p -n stat 2>&1 | \
                   awk '/RMS[ \t\n]+amplitude:/ { print int($3*32768) }'`
  if ((rms_start > THRESHOLD_RMS)); then
    echo "Suspicious start RMS:${rms_start} ${1}"
    return 1
  fi
}

wav_not_silence() {
  local voiced_samples=`sox "${1}" -p silence 1 "${PADDING_IN_SECONDS}" 3% | \
                        sox -p -n stat 2>&1 | \
                        awk '/Samples[ \t\n]+read:/ { print int($3) }'`
  if ((voiced_samples < THRESHOLD_VOICE)); then
    echo "Suspicious silence: ${voiced_samples} ${1}"
    return 1
  fi
}

wav_is_good() {
  wav_size_ok "${1}" && wav_not_silence "${1}" &&
  wav_left_padded "${1}" && wav_right_padded "${1}"
}

check_dataset_md5() {
  local expected=$1
  local src=${2:-${DATASET_DIR}}
  local md5
  echo "Checking md5 ${src}..."
  if [ -d "${src}" ]; then
    md5=`cd "${src}" && find . -type f -print0 | sort -z | xargs -0 md5sum | md5sum | awk '{ print $1 }'`
  else
    md5=`md5sum "${src}" | awk '{ print $1 }'`
  fi
  if [ "${expected}" != "${md5}" ]; then
    echo "ASSERT: md5 mismatch ${expected} != ${md5}"
    rm -r "${DATASET_DIR}"
    exit 1
  fi
}

if [ ! -d "${DATASET_DIR}" ]; then

  wget --directory-prefix="${DATASET_DIR}" "${HTTP_URL}"

  base=`basename "${HTTP_URL}"`

  check_dataset_md5 '6b74f3901214cb2c2934e98196829835' "${DATASET_DIR}/${base}"

  echo "Extracting ${base}..."
  tar zxf "${DATASET_DIR}/${base}" \
    --checkpoint-action=ttyout="#%u: %T\r" \
    -C "${DATASET_DIR}"
  rm "${DATASET_DIR}/${base}"

  check_dataset_md5 '645d7b9d9ea755e961e3d5e77ec96fb6'

  # google dataset is very messy, cleanup duplicates

  for dir in `find "${DATASET_DIR}" -mindepth 1 -type d`; do
    echo "Removing duplicates from ${dir}..."
    fdupes -rdN --order=name "${dir}"
  done

  echo "Checking whole dataset for duplicates, be patient..."
  if [ '0' != `fdupes -r "${DATASET_DIR}" | wc -l` ]; then
    echo "ASSERT: can't fix google dataset"
    exit 2
  fi

  mkdir "${HUMAN_WORDS_DIR}"
  for dir in `find "${DATASET_DIR}" -mindepth 1 -type d`; do
    if [ "${dir}" == "${DATASET_NOISE_DIR}" ]; then
      continue
    fi

    if [ "${dir}" == "${HUMAN_WORDS_DIR}" ]; then
      continue
    fi

    mv "${dir}" "${HUMAN_WORDS_DIR}"
  done

  check_dataset_md5 '80b36cc44988671c4cd612bea603399e' "${HUMAN_WORDS_DIR}"

  # cleanup suspicious wav samples

  for wav in `find "${HUMAN_WORDS_DIR}" -name '*.wav'`; do
    wav_is_good "${wav}" || rm "${wav}"
  done

  check_dataset_md5 '24df99d3a10e83de33b2ebe3c3172c10' "${HUMAN_WORDS_DIR}"

  echo 'Slicing to 1s...'
  find "${DATASET_NOISE_DIR}" -name '*.wav' \
    | xargs -I{} sox -V1 {} {} trim 0 1 : newfile : restart

  for wav in `find "${DATASET_NOISE_DIR}" -name '*.wav'`; do
    wav_size_ok "${wav}" || rm "${wav}"
  done

  check_dataset_md5 '3a5da20a4a1ba1329deddd83f8720676' "${DATASET_NOISE_DIR}"

  # actualize *.txt files

  find "${HUMAN_WORDS_DIR}" -name '*.wav' \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | grep -x -F -f "${DATASET_DIR}/${DATASET_VALIDATION_FILE}" \
    > "${HUMAN_WORDS_DIR}/${DATASET_VALIDATION_FILE}"

  find "${HUMAN_WORDS_DIR}" -name '*.wav' \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | grep -x -F -f "${DATASET_DIR}/${DATASET_TESTING_FILE}" \
    > "${HUMAN_WORDS_DIR}/${DATASET_TESTING_FILE}"

  find "${HUMAN_WORDS_DIR}" -name '*.wav' \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | grep -x -v -F -f "${DATASET_DIR}/${DATASET_VALIDATION_FILE}" -f "${DATASET_DIR}/${DATASET_TESTING_FILE}" \
    > "${HUMAN_WORDS_DIR}/${DATASET_TRAINING_FILE}"

  rm "${DATASET_DIR}/${DATASET_VALIDATION_FILE}" "${DATASET_DIR}/${DATASET_TESTING_FILE}"

  find "${DATASET_NOISE_DIR}" -name '*.wav' \
    | sort \
    | awk -F '/' '{ print $NF }' \
    > "${DATASET_NOISE_FILE}"

  check_dataset_md5 '6d2e5ab9bd67ffb89fbed1bbf8bde847'

fi