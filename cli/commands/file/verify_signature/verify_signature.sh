#!/bin/bash

echo "entering decrypt.sh"

# echo "BCM_TREZOR_FILE_PATH: $BCM_TREZOR_FILE_PATH"

# INPUT_FILE_DIR=$(dirname $BCM_TREZOR_FILE_PATH)
# INPUT_FILE_NAME=$(basename $BCM_TREZOR_FILE_PATH)

# echo "INPUT_FILE_DIR: $INPUT_FILE_DIR"
# echo "INPUT_FILE_NAME: $INPUT_FILE_NAME"

# docker run -it -v $BCM_PROJECT_DIR:/home/user/.gnupg \
#     -v $INPUT_FILE_DIR:/sigdir \
#     "bcm-trezor:$BCM_VERSION" gpg --verify /sigdir/$INPUT_FILE_NAME.sig /sigdir/$INPUT_FILE_NAME
