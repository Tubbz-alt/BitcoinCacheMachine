#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the manager BCM tier is up and running.
if bcm tier list | grep -q "bitcoin$BCM_ACTIVE_CHAIN"; then
    echo "The 'bitcoin$BCM_ACTIVE_CHAIN' tier is already provisioned."
    exit
fi

# don't even think about proceeding unless the manager BCM tier is up and running.
if ! bcm tier list | grep -q "underlay"; then
    bcm tier create underlay
fi

# Let's provision the system containers to the cluster.
../create_tier.sh --tier-name=bitcoin"$BCM_ACTIVE_CHAIN"
