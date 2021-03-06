#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# source the bitcoind information so we can pass it to the stack.
# shellcheck source=../bitcoind/env.sh
source "$BCM_STACKS_DIR/bitcoind/env.sh"

# override anything from bitcoind/env.sh
source ./env.sh

# prepare the image.
"$BCM_LXD_OPS/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack" "$BCM_MANAGER_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"
IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION"

lxc exec "$BCM_MANAGER_HOST_NAME" -- env IMAGE_NAME="$IMAGE_NAME" \
BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
CHAIN_TEXT="$CHAIN_TEXT" \
TOR_SOCKS5_PROXY_HOSTNAME="$BCM_MANAGER_HOST_NAME" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"

# wait for the REST API to come online.
lxc exec "$BCM_BITCOIN_HOST_NAME" -- docker run --rm "$IMAGE_NAME" --network "lnd-$BCM_ACTIVE_CHAIN""_lndrpcnet" wait-for-it -t 30 "lndrpc-$BCM_ACTIVE_CHAIN:8080"

# we require upstream apps (e.g., RTL) to perform wallet initialization.
