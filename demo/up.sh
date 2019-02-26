#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# Init your SDN controller; create a new GPG certificate 'Satoshi Nakamoto satoshi@bitcoin.org'
bcm init --cert-name="Satoshi Nakamoto" --username="satoshi" --hostname="bitcoin.org"

# Create a new BCM cluster master on your localhost.
bcm cluster create --cluster-name="LocalCluster" --ssh-username="$(whoami)" --ssh-hostname="$(hostname)"

# provisions critical BCM datacenter workloads. Required before running 'bcm stack deploy'.
bcm provision

bcm stack deploy bitcoind --chain=testnet
bcm stack deploy clightning --chain=testnet

# some ENV VARS that are useful for development
#export BCM_DEBUG=1
#export DOCKER_IMAGE_CACHE="cachestack.domainname.tld"
