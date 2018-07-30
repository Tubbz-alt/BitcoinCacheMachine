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

echo "Applying ./bitcoin_lxd_profile.yml to lxd profile 'bitcoinprofile'."
cat ./bitcoin_lxd_profile.yml | lxc profile edit bitcoinprofile


# create the profile 'bitcoinprofile'
if [[ -z $(lxc profile list | grep bitcoinprofile) ]]; then
    # create the bitcoin profile
    lxc profile create bitcoinprofile
else
  echo "LXD profile bitcoinprofile already exists, skipping initial creation."
fi


## Create the manager1 host from the lxd image template.
lxc init bctemplate bitcoin -p docker -p dockertemplate_profile -s $BC_ZFS_POOL_NAME

echo "Applying the lxd profiles 'bitcoinprofile' and 'docker' to the lxd host 'bitcoin'."
lxc profile apply bitcoin docker,bitcoinprofile

# Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
lxc storage create bitcoin-dockervol dir
lxc config device add bitcoin dockerdisk disk source=$(lxc storage show bitcoin-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker


if [[ $BCM_DISABLE_DOCKER_GELF = "true" ]]; then
  # push docker.json for registry mirror settings
  lxc file push ./dockerd_nogelf.json bitcoin/etc/docker/daemon.json
else
  # push docker.json for registry mirror settings
  lxc file push ./dockerd.json bitcoin/etc/docker/daemon.json
fi


lxc start bitcoin

sleep 10

# update routing table in bitcoin lxd host to prefer eth0 for outbound access.
lxc exec bitcoin -- ifmetric eth0 0

WORKER_TOKEN=$(lxc exec manager1 -- docker swarm join-token worker | grep token | awk '{ print $5 }')

lxc exec bitcoin -- docker swarm join 10.0.0.11 --token $WORKER_TOKEN

# create the external bitcoind data volume
lxc exec bitcoin -- docker volume create bitcoind-data


############################
############################

# install bitcoid if specified
if [[ $BCM_INSTALL_BITCOIN_BITCOIND = "true" ]]; then
  echo "Deploying bitcoind services to lxd host 'bitcoin'."
  lxc exec manager1 -- mkdir -p /apps/bitcoind

  lxc file push ./stacks/bitcoind/bitcoind-mainnet.conf manager1/apps/bitcoind/bitcoind-mainnet.conf
  lxc file push ./stacks/bitcoind/bitcoind-testnet.conf manager1/apps/bitcoind/bitcoind-testnet.conf
  lxc file push ./stacks/bitcoind/bitcoind.yml manager1/apps/bitcoind/bitcoind.yml
  lxc file push ./stacks/bitcoind/torrc.conf manager1/apps/bitcoind/torrc.conf

  lxc exec manager1 -- docker stack deploy -c /apps/bitcoind/bitcoind.yml bitcoind
fi



# install lightningd (c-lightning) if specified
if [[ $BCM_INSTALL_BITCOIN_LIGHTNINGD = "true" ]]; then
  echo "Deploying lightningd (c-lightning) to lxd host 'bitcoin'."
  lxc exec manager1 -- mkdir -p /apps/lightningd

  lxc file push ./stacks/lightningd/lightningd-mainnet.conf manager1/apps/lightningd/lightningd-mainnet.conf
  lxc file push ./stacks/lightningd/lightningd-testnet.conf manager1/apps/lightningd/lightningd-testnet.conf
  lxc file push ./stacks/lightningd/lightningd.yml manager1/apps/lightningd/lightningd.yml
  lxc file push ./stacks/lightningd/torrc.conf manager1/apps/lightningd/torrc.conf

  lxc exec manager1 -- docker stack deploy -c /apps/lightningd/lightningd.yml lightningd
fi


# install lnd if specified
if [[ $BCM_INSTALL_BITCOIN_LND = "true" ]]; then
echo "Deploying lightning network daemon (lnd) to lxd host 'bitcoin'."
lxc exec manager1 -- mkdir -p /apps/lnd

lxc file push ./stacks/lnd/lnd-mainnet.conf manager1/apps/lnd/lnd-mainnet.conf
lxc file push ./stacks/lnd/lnd-testnet.conf manager1/apps/lnd/lnd-testnet.conf
lxc file push ./stacks/lnd/lnd.yml manager1/apps/lnd/lnd.yml

lxc exec manager1 -- docker stack deploy -c /apps/lnd/lnd.yml lnd



echo "Deploying lncli-web web interface (for lnd) lxd host 'bitcoin'."
lxc exec manager1 -- mkdir -p /apps/lncliweb

lxc file push ./stacks/lncliweb/lncli-web.yml manager1/apps/lncliweb/lncli-web.yml
lxc file push ./stacks/lncliweb/lncli-web.lncliweb.conf.js manager1/apps/lncliweb/lncli-web.lncliweb.conf.js
lxc file push ./stacks/lncliweb/nginx.conf manager1/apps/lncliweb/nginx.conf

lxc exec manager1 -- docker stack deploy -c /apps/lncliweb/lncli-web.yml lncli-web





# # if IPFS_bootstrap is true, then we will download pre-indexed blockchain data, etc, via IPFS
# # consider running a bitcoin cache stack on your local network to speed up deployment and avoid
# # use of your internet connection.
# if [[ $BCM_DEPLOYMENT_IPFS_BOOTSTRAP = "true" ]]; then
#     echo "Downloading a pre-validated and pre-indexed copy of the bitcoin blockchain."
#     echo "WARNING: By using this method, you are trusting the developers of BCM as well as the computer that created the IPFS Hash!"
#     echo "         Use for development purposes only unless you understand the risks and need to get a working BCM fast!  Consider adding"
#     echo "         a bcm_cache_stack to your local network to improve deployment time and avoid Internet connection use."
#     lxc exec bitcoin -- docker run -d --rm --name bitcoin_ipfs_bootstrapper -v bitcoind-data:/bitcoindata ipfs/go-ipfs:latest
    
#     # wait for ipfs services to come online
#     sleep 30

#     if [ $BCM_BITCOIN_CHAIN = "testnet" ]; then
#         echo "Calling ipfs get to download the bitcoin testnet pre-indexed block data."
#         lxc exec bitcoin -- docker exec -it bitcoin_ipfs_bootstrapper ipfs get --output=/bitcoindata QmQftBHZwTa3phAEDLp1Cdx5pJG3gexjbeooZw9ogU1WcG
#     elif [ $BCM_BITCOIN_CHAIN = "mainnet" ]; then
#         # TODO - get hash of mainnet data for IPFS bootstrap
#         lxc exec bitcoin -- docker exec -it bitcoin_ipfs_bootstrapper ipfs get GETHASHFORMAINNETDATA
#     else
#         echo "Wrong value set for BCM_BITCOIN_CHAIN environment variable."
#         exit 1
#     fi
# fi

# echo "Deploying bitcoind."
# lxc exec manager1 -- docker stack deploy -c /apps/bitcoin/bitcoind/bitcoind.yml bitcoind

