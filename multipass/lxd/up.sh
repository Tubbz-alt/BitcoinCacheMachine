#!/bin/bash

# stop scrtip if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# Source the LXD environment variables maintained by the user in ~/.bcm/lxd.env.sh
source ~/.bcm/lxd.env.sh

# get or update the BCM host template git repo
if [[ $BC_INSTALLATION_PATH = "bcm" ]]; then
  export BC_ZFS_POOL_NAME="bcm_data"
  bash -c ./bcm/up_lxd.sh
elif [[ $BC_INSTALLATION_PATH = "bcs" ]]; then

  echo "Clearing LXD http proxy settings. Bitcoin Cache Stack will download from the Internet."
  lxc config set core.proxy_https ""
  lxc config set core.proxy_http ""
  lxc config set core.proxy_ignore_hosts ""

  # Create a docker host template if it doesn't exist already
  if [[ -z $(lxc list | grep dockertemplate) ]]; then
    export BC_ZFS_POOL_NAME="bcs_data"
      # Create a docker host template if it doesn't exist already
    if [[ -z $(lxc list | grep $BC_ZFS_POOL_NAME) ]]; then
      # create the host template if it doesn't exist already.
      bash -c ./host_template/up_lxd.sh
    fi

    # if the template doesn't exist, publish it create it.
    if [[ -z $(list image list | grep bctemplate) ]]; then
      echo "Publishing dockertemplate/dockerSnapshot snapshot as bctemplate lxd image."
      lxc publish $(lxc remote get-default):dockertemplate/dockerSnapshot --alias bctemplate
    fi    
  else
    echo "Skipping creation of the host template. Snapshot already exists."
  fi  


  echo "Calling Bitcoin Cache Stack Installation Script."
  bash -c ./bcs/up_lxd.sh
fi