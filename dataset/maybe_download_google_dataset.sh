#!/bin/bash

set -e

DATASET_DIR=$1
HUMAN_WORDS_DIR="${DATASET_DIR}/_human_words_"
HTTP_URL='http://download.tensorflow.org/data/speech_commands_v0.02.tar.gz'

DATASET_NOISE_DIR="${DATASET_DIR}/_background_noise_"
DATASET_TESTING_FILE='testing_list.txt'
DATASET_TRAINING_FILE='training_list.txt'
DATASET_VALIDATION_FILE='validation_list.txt'

THRESHOLD_RMS=2000     # wav filter
THRESHOLD_VOICE=5000   # wav filter
PADDING_IN_SECONDS=0.1 # wav filter

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

if [ ! -d "${DATASET_DIR}" ]; then

  wget --directory-prefix="${DATASET_DIR}" "${HTTP_URL}"

  base=`basename "${HTTP_URL}"`

  echo "Checking md5 ${base}..."
  md5=`md5sum "${DATASET_DIR}/${base}" | awk '{ print $1 }'`
  if [ "6b74f3901214cb2c2934e98196829835" != "${md5}" ]; then
    echo "ASSERT: ${DATASET_DIR}/${base} md5 mismatch"
    exit 1
  fi

  echo "Extracting ${base}..."
  tar zxf "${DATASET_DIR}/${base}" \
    --checkpoint-action=ttyout="#%u: %T\r" \
    -C "${DATASET_DIR}"

  # google dataset is very messy, cleanup duplicates

  for dir in `find "${DATASET_DIR}" -mindepth 1 -type d`; do
    echo "Removing duplicates from ${dir} ..."
    fdupes -rdN "${dir}"
  done

  echo "Checking whole dataset for duplicates, be patient ..."
  if [ ! -z `fdupes -r "${DATASET_DIR}"` ]; then
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

  # cleanup suspicious wav samples

  for wav in `find "${HUMAN_WORDS_DIR}" -name '*.wav'`; do
    wav_is_good "${wav}" || rm "${wav}"
  done

  # make some noise

  find "${DATASET_NOISE_DIR}" -name '*.wav' \
    | xargs -I{} sox -V1 {} {} trim 0 1 : newfile : restart

  for wav in `find "${DATASET_NOISE_DIR}" -name '*.wav'`; do
    wav_size_ok "${wav}" || rm "${wav}"
  done

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

fi
