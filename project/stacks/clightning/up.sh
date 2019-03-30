#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./env

# first, let's make sure we deploy our direct dependencies.
bcm stack deploy bitcoind

# this is the LXC host that the docker container is going to be provisioned to.
HOST_ENDING="01"
CONTAINER_NAME="bcm-$TIER_NAME-$HOST_ENDING"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build" \
--container-name="$CONTAINER_NAME" \
--image-name="$IMAGE_NAME" \
--image-tag="$IMAGE_TAG"

# push the stack and build files
lxc file push -p -r "$(pwd)/stack/" "$BCM_GATEWAY_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" \
CHAIN="$BCM_DEFAULT_CHAIN" \
HOST_ENDING="$HOST_ENDING" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_FILE" "$STACK_NAME-$BCM_DEFAULT_CHAIN"

DEST_DIR="/var/lib/docker/volumes/clightning-""$BCM_DEFAULT_CHAIN""_clightning-data/_data"
if ! lxc exec "$CONTAINER_NAME" -- [ -f "$DEST_DIR/gogo" ]; then
    lxc exec "$CONTAINER_NAME" -- mkdir -p "$DEST_DIR"
    lxc exec "$CONTAINER_NAME" -- touch "$DEST_DIR/gogo"
fi
