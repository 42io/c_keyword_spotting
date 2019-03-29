#!/bin/bash

set -e
set -u

export LC_ALL=C

cd "`dirname "${BASH_SOURCE[0]}"`"

readonly DATASET_SOURCE_DIR='/tmp/google_speech_commands'
readonly DATASET_WANTED_DIR='/tmp/wanted_speech_commands'
readonly PUB_DOMAIN_SND_DIR='/tmp/public_domain_sounds'
readonly FEATURES_DATA_FILE='/tmp/c_kws.data'
readonly WANTED_WORDS=${@}
readonly UNKNWN_WORD=#unk#
readonly PUBLIC_WORD=#pub#

bash maybe_download_google_dataset.sh "${DATASET_SOURCE_DIR}"
bash maybe_download_public_sounds.sh "${PUB_DOMAIN_SND_DIR}"
bash create_dataset_for_keywords.sh "${DATASET_SOURCE_DIR}" "${DATASET_WANTED_DIR}" "${WANTED_WORDS}"
bash augment_dataset.sh "${DATASET_SOURCE_DIR}" "${DATASET_WANTED_DIR}" "${WANTED_WORDS}"
bash append_unk_words_to_dataset.sh "${DATASET_SOURCE_DIR}" "${DATASET_WANTED_DIR}" "${UNKNWN_WORD}" "${WANTED_WORDS}"
bash append_pub_snd_to_dataset.sh "${PUB_DOMAIN_SND_DIR}" "${DATASET_WANTED_DIR}" "${PUBLIC_WORD}" "${WANTED_WORDS}"
bash extract_features.sh "${FEATURES_DATA_FILE}" "${DATASET_WANTED_DIR}" "${UNKNWN_WORD}" "${PUBLIC_WORD}" "${WANTED_WORDS}"
bash train_brain.sh "${FEATURES_DATA_FILE}" "${DATASET_WANTED_DIR}" "${UNKNWN_WORD}" "${PUBLIC_WORD}" "${WANTED_WORDS}"