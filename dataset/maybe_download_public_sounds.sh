#!/bin/bash

set -e
set -u

readonly DATASET_DIR=$1
readonly HTTP_URL='http://downloads.tuxfamily.org/pdsounds/pdsounds_march2009.7z'
readonly DATASET_1S_DIR="${DATASET_DIR}/_1s_"

readonly DATASET_TESTING_FILE='testing_list.txt'
readonly DATASET_TRAINING_FILE='training_list.txt'
readonly DATASET_VALIDATION_FILE='validation_list.txt'

# functions

wav_size_ok() {
  local wav_size_in_frames=`sox --info -s "${1}"`
  if ((wav_size_in_frames != 16000)); then
    echo "Suspicious size: ${wav_size_in_frames} ${1}"
    return 1
  fi
  return 0
}

shuf() {
  mawk 'BEGIN {srand(42); OFMT="%.17f"} {print rand(), $0}' \
    | sort -k1,1n | awk '{print $2}'
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

  check_dataset_md5 'c16eab87321f2edc8237473003f09841' "${DATASET_DIR}/${base}"

  echo "Extracting ${base}..."
  7za -o"${DATASET_DIR}" \
       x "${DATASET_DIR}/${base}" | grep -v '^Extracting'
  rm "${DATASET_DIR}/${base}"

  check_dataset_md5 '5cabf725d23b191f6bb72bfe76dde28d'

  echo 'Converting mp3 to wav...'

  find "${DATASET_DIR}/mp3" -name '*.mp3' -print0 \
    | xargs -0 -I{} mpg123 -q -w "{}.wav" -e s16 -r 16000 -m "{}"

  mkdir "${DATASET_1S_DIR}"
  mv ${DATASET_DIR}/mp3/*.wav "${DATASET_1S_DIR}"

  check_dataset_md5 'e8259f0925beb85f1060c335bb349c8d' "${DATASET_1S_DIR}"

  echo 'Slicing to 1s...'
  find "${DATASET_1S_DIR}" -name '*.wav' -print0 \
    | xargs -0 -I{} sox -V1 {} {} trim 0 1 : newfile : restart

  check_dataset_md5 '63254c99d10ff746c522b6747d7c2661' "${DATASET_1S_DIR}"

  for wav in ${DATASET_1S_DIR}/*.wav; do
    dest="${DATASET_1S_DIR}/1s_`basename "${wav// /_}"`"
    mv "${wav}" "${dest}"
    wav_size_ok "${dest}" || rm "${dest}"
  done

  echo "Checking for duplicates, be patient..."
  fdupes -rdN --order=name "${DATASET_1S_DIR}"

  check_dataset_md5 '2d596c345456d6874e0e3a2640c1ce22' "${DATASET_1S_DIR}"

  find "${DATASET_1S_DIR}" -name '*.wav' \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | shuf \
    | head -20000 \
    | sort \
    > "${DATASET_DIR}/${DATASET_TRAINING_FILE}"

  find "${DATASET_1S_DIR}" -name '*.wav' \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | grep -x -v -F -f "${DATASET_DIR}/${DATASET_TRAINING_FILE}" \
    | shuf \
    | head -1000 \
    | sort \
    > "${DATASET_DIR}/${DATASET_TESTING_FILE}"

  find "${DATASET_1S_DIR}" -name '*.wav' \
    | sort \
    | awk -F '/' '{ print $(NF-1)"/"$NF }' \
    | grep -x -v -F -f "${DATASET_DIR}/${DATASET_TRAINING_FILE}" -f "${DATASET_DIR}/${DATASET_TESTING_FILE}" \
    | shuf \
    | head -1000 \
    | sort \
    > "${DATASET_DIR}/${DATASET_VALIDATION_FILE}"

  check_dataset_md5 'df815782f635c48a78079de75d3a934a'

fi