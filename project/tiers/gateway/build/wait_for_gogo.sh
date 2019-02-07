#!/bin/bash

set -Eeu

GOGO_FILE=

for i in "$@"; do
    case $i in
        --gogofile=*)
            GOGO_FILE="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done


if [[ ! -z "$GOGO_FILE" ]]; then
    # we are going to wait for GOGO_FILE to appear before starting bitcoind.
    # this allows the management plane to upload the blocks and/or chainstate.
    while [ ! -f "$GOGO_FILE" ]
    do
        sleep .5
        printf '.'
    done
    
    echo ""
else
    echo "ERROR: GOGO_FILE not specified."
fi