#!/bin/bash

# quit script if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# create the lxdbrBitcoin network, which is used for all outbound access
# by services residing on the lxd host `bitcoin`
if [[ -z $(lxc network list | grep lxdbrBitcoin) ]]; then
    # a bridged network created for all services residing on the LXC host 'bitcoin'
    lxc network create lxdbrBitcoin ipv4.nat=true
else
  echo "LXD network lxdbrBitcoin already exists, skipping initial creation."
fi

# create the profile 'bitcoinprofile'
if [[ -z $(lxc profile list | grep bitcoinprofile) ]]; then
    # create the bitcoin profile
    lxc profile create bitcoinprofile
else
  echo "LXD profile bitcoinprofile already exists, skipping initial creation."
fi


echo "Applying bitcoin lxd profile file to lxd profile 'bitcoinprofile'."
cat ./bitcoin_lxd_profile.yml | lxc profile edit bitcoinprofile

## Create the manager1 host from the lxd image template.
lxc init bcm-template bitcoin -p docker -p docker_privileged -s $bcm_data

echo "Applying the lxd profiles 'bitcoinprofile' and 'default' to the lxd host 'bitcoin'."
lxc profile apply bitcoin default,bitcoinprofile



# create the bitcoin-dockervol storage pool.
## TODO refactor this method out for re-use (any up/down 'host-dockervol')
if [[ -z $(lxc storage list | grep "bitcoin-dockervol") ]]; then
    # Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
    lxc storage create bitcoin-dockervol dir
    lxc config device add bitcoin dockerdisk disk source=$(lxc storage show bitcoin-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
else
    echo "bitcoin-dockervol lxd storage pool already exists; attaching it to lxc container 'bitcoin'."
    lxc config device add bitcoin dockerdisk disk source=$(lxc storage show bitcoin-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker
fi

if [[ $BCM_BITCOIN_DISABLE_DOCKER_GELF = "true" ]]; then
  # push docker.json for registry mirror settings
  lxc file push ./dockerd_nogelf.json bitcoin/etc/docker/daemon.json
else
  # push docker.json for registry mirror settings
  lxc file push ./dockerd.json bitcoin/etc/docker/daemon.json
fi


lxc start bitcoin

sleep 10

# update routing table in bitcoin lxd host to prefer eth0 for outbound access.
# TODO Find a better way to pin outbound traffic to eth0
lxc exec bitcoin -- ifmetric eth0 0




WORKER_TOKEN=$(lxc exec manager1 -- docker swarm join-token worker | grep token | awk '{ print $5 }')

lxc exec bitcoin -- docker swarm join 10.0.0.11 --token $WORKER_TOKEN

############################
############################

# install bitcoid if specified
if [[ $BCM_INSTALL_BITCOIN_BITCOIND_TESTNET = "true" ]]; then
  bash -c ./stacks/bitcoind/up_lxd_bitcoind.sh
fi



# install lightningd (c-lightning) if specified (testnet)
if [[ $BCM_INSTALL_BITCOIN_LIGHTNINGD_TESTNET = "true" ]]; then
  bash -c ./stacks/lightningd/up_lxd_lightningd.sh
fi

# install lightningd (c-lightning) if specified (testnet)
if [[ $BCM_INSTALL_BITCOIN_LND_TESTNET = "true" ]]; then
  bash -c ./stacks/lnd/up_lxd_lnd.sh
fi

