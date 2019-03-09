#!/bin/bash

# Init your SDN controller; create a new GPG certificate 'Satoshi Nakamoto satoshi@bitcoin.org'
bcm init --cert-name="Satoshi Nakamoto" --username="satoshi" --hostname="bitcoin.org"

# Create a cluster on a remote machine
# bcm cluster create --driver=ssh --cluster-name="hostname" --ssh-username="bcm" --ssh-hostname="fqdn"
bcm cluster create

# deploy bcm components
bcm stack deploy clightning --chain=testnet
bcm stack deploy bitcoind --chain=testnet
