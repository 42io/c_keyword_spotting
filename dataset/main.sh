#!/bin/bash

set -e

cd "`dirname "${BASH_SOURCE[0]}"`"

DATASET_SOURCE_DIR='/tmp/google_speech_commands'
DATASET_WANTED_DIR='/tmp/wanted_speech_commands'
FEATURES_DATA_FILE='/tmp/c_kws.data'
WANTED_WORDS=${@}
UNKNWN_WORD=#unk#

bash maybe_download_google_dataset.sh "${DATASET_SOURCE_DIR}"
bash create_dataset_for_keywords.sh "${DATASET_SOURCE_DIR}" "${DATASET_WANTED_DIR}" "${UNKNWN_WORD}" "${WANTED_WORDS}"
bash augment_dataset.sh "${DATASET_SOURCE_DIR}" "${DATASET_WANTED_DIR}" "${UNKNWN_WORD}" "${WANTED_WORDS}"

bash extract_features.sh "${FEATURES_DATA_FILE}" "${DATASET_WANTED_DIR}" "${UNKNWN_WORD}" "${WANTED_WORDS}"
bash train_brain.sh "${FEATURES_DATA_FILE}" "${DATASET_WANTED_DIR}" "${UNKNWN_WORD}" "${WANTED_WORDS}"