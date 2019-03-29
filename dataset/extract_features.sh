#!/bin/bash

set -e
set -u

readonly DATA_FILE=$1
readonly DATASET_WANTED_DIR=$2
readonly UNKNWN_WORD=$3
readonly PUBLIC_WORD=$4
readonly WANTED_WORDS=${@:5}

declare -i output_num=0
declare -i output_idx=0

if [ '1' != `find "${DATASET_WANTED_DIR}/training/" -mindepth 1 -type d | xargs -I{} sh -c 'ls "{}" | wc -l' | sort -u | wc -l` ]; then
  echo "ASSERT: each train directory should have equal file count"
  exit 1
fi

echo "Checking keyword dataset for duplicates..."
if [ '0' != `fdupes -r "${DATASET_WANTED_DIR}" | wc -l` ]; then
  echo "ASSERT: duplicates found"
  exit 2
fi

for word in ${WANTED_WORDS} ${UNKNWN_WORD} ${PUBLIC_WORD} ; do
  output_num+=1
done

bash ./../src/features/build.sh

echo -n `find "${DATASET_WANTED_DIR}/training/" -type f | wc -l` > "${DATA_FILE}"
echo -n ' ' >> "${DATA_FILE}"
echo -n `find "${DATASET_WANTED_DIR}/training/" -type f | head -n 1 | xargs ./../bin/fe | tr ' ' '\n' | wc -l` >> "${DATA_FILE}"
echo -n ' ' >> "${DATA_FILE}"
echo "${output_num}" >> "${DATA_FILE}"

out_to_vec() {
  local num=$1
  local idx=$2
  local i
  for i in `seq 1 ${num}`; do
    if ((i != 1)); then
      echo -n ' '
    fi
    if ((i == idx))
    then
      echo -n '1'
    else
      echo -n '0'
    fi
  done
  echo
}

for word in ${WANTED_WORDS} ${UNKNWN_WORD} ${PUBLIC_WORD} ; do
  echo "Extracting features ${word}..."
  output_idx+=1
  for wav in `find "${DATASET_WANTED_DIR}/training/${word}/" -type f | sort`; do
    ./../bin/fe "${wav}" >> "${DATA_FILE}"
    out_to_vec "${output_num}" "${output_idx}" >> "${DATA_FILE}"
  done
done

words_from_demo() {
  if [ 'zeroonetwothreefourfivesixseveneightnine' == "${WANTED_WORDS//[[:blank:]]/}" ]
  then
    return 1
  fi
  return 0
}

check_datafile_md5() {
  local expected=$1
  local src=${DATA_FILE}
  local md5
  echo "Checking md5 ${src}..."
  md5=`md5sum "${src}" | awk '{ print $1 }'`
  if [ "${expected}" != "${md5}" ]; then
    echo "ASSERT: md5 mismatch ${expected} != ${md5}"
    exit 3
  fi
}

words_from_demo || check_datafile_md5 '8722d1b5b6e1a6b1419a257c4cb0421d'