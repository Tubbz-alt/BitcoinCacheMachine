
#!/bin/env

# Multipass options
export MULTIPASS_VM_NAME=""
export MULTIPASS_DISK_SIZE="50G"
export MULTIPASS_MEM_SIZE="4G"
export MULTIPASS_CPU_COUNT="4"

# Bitcoin Cache Machine and Cache Stack options
export BC_ATTACH_TO_UNDERLAY="false"
export BC_CACHESTACK_STANDALONE="false"

# if BC_ATTACH_TO_UNDERLAY=true, this physical interface will macvlan the interface
# to get network underlay access.
export BCS_TRUSTED_HOST_INTERFACE=""


# Cache Stack installation options.
export BCS_INSTALL_BITCOIND_TESTNET="false"
export BCS_INSTALL_BITCOIND_MAINNET="false"
export BCS_INSTALL_IPFSCACHE="false"
export BCS_INSTALL_PRIVATEREGISTRY="false"
export BCS_INSTALL_REGISTRYMIRRORS="false"
export BCS_INSTALL_SQUID="false"
export BCS_INSTALL_TOR_SOCKS5_PROXY="false"

# BCM specific options.

# If there is a standalone cachestack installed on the network, you can specify it here.
# whatever you put here MUST be defined as an LXD endpoint on the administrative machine.
export BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT="none"

# BCM installation and deployment options.
export BCM_DEPLOYMENT_IPFS_BOOTSTRAP="false"
export BCM_INSTALL_BITCOIN_BITCOIND="false"
export BCM_INSTALL_BITCOIN_LIGHTNINGD="false"
export BCM_INSTALL_BITCOIN_LND="false"


## debugging
export BC_LXD_IMAGE_BCTEMPLATE_DELETE="false"
export BC_HOST_TEMPLATE_DELETE="false"
export BC_DELETE_CACHESTACK="false"
export BCM_DISABLE_DOCKER_GELF="false"


# secret data
# todo seed based on hardware wallet standard.
export BC_LXD_SECRET="You_Should_Change_This"

# shouldn't need to change
export BC_ZFS_POOL_NAME="bc_data"