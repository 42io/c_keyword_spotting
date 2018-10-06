#!/bin/bash

set -e

DEST_DIR=$1
HTTP_URL='http://download.tensorflow.org/data/speech_commands_v0.02.tar.gz'

DATASET_NOISE_DIR="${DEST_DIR}/_background_noise_"
DATASET_TESTING_FILE="${DEST_DIR}/testing_list.txt"
DATASET_TRAINING_FILE="${DEST_DIR}/training_list.txt"
DATASET_VALIDATION_FILE="${DEST_DIR}/validation_list.txt"

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

if [ ! -d "${DEST_DIR}" ]; then

  wget --directory-prefix="${DEST_DIR}" "${HTTP_URL}"

  base=`basename ${HTTP_URL}`

  echo "Checking md5 ${base}..."
  md5=`md5sum "${DEST_DIR}/${base}" | awk '{ print $1 }'`
  if [ "6b74f3901214cb2c2934e98196829835" != "${md5}" ]; then
    echo "ASSERT: ${DEST_DIR}/${base} md5 mismatch"
    exit 1
  fi

  echo "Extracting ${base}..."
  tar zxf "${DEST_DIR}/${base}" \
    --checkpoint-action=ttyout="#%u: %T\r" \
    -C "${DEST_DIR}"

  # google dataset is very messy, cleanup duplicates

  for dir in `find "${DEST_DIR}" -mindepth 1 -type d`; do
    echo "Removing duplicates from ${dir} ..."
    fdupes -rdN "${dir}"
  done

  echo "Checking whole dataset for duplicates, be patient ..."
  if [ ! -z `fdupes -r "${DEST_DIR}"` ]; then
    echo "ASSERT: can't fix google dataset"
    exit 2
  fi

  # cleanup suspicious wav samples

  for wav in `find "${DEST_DIR}" -name "*.wav"`; do
    wav_is_good "${wav}" || rm "${wav}"
  done

  # actualize *.txt files

  tfile=`mktemp`

  find "${DEST_DIR}" -name "*.wav" \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | grep -F -f "${DATASET_VALIDATION_FILE}" > "${tfile}"
  mv "${tfile}" "${DATASET_VALIDATION_FILE}"

  find "${DEST_DIR}" -name "*.wav" \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | grep -F -f "${DATASET_TESTING_FILE}" > "${tfile}"
  mv "${tfile}" "${DATASET_TESTING_FILE}"

  if [ -f "${DATASET_TRAINING_FILE}" ]; then
    echo "ASSERT: ${DATASET_TRAINING_FILE} was not here before"
    exit 3
  fi

  find "${DEST_DIR}" -name "*.wav" -not -path "${DATASET_NOISE_DIR}/*" \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | grep -v -F -f "${DATASET_VALIDATION_FILE}" -f "${DATASET_TESTING_FILE}" \
    > "${DATASET_TRAINING_FILE}"

fi
