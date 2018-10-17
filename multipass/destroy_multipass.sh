#!/bin/bash

set -eu

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

VM_NAME=$1

if [[ $(multipass list | grep $VM_NAME) ]]; then
  export BCM_MULTIPASS_VM_NAME=$VM_NAME

  if [[ -f ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME/.env ]]; then
    source ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME/.env
  fi
fi

# quit if there are no multipass environment variables loaded.
if [[ -z $(env | grep "BCM_MULTIPASS_VM_NAME") ]]; then
  echo "BCM_MULTIPASS_VM_NAME variable not set."
  exit 1
fi

# Stopping multipass vm $MULTIPASS_VM_NAME
if [[ $(multipass list | grep "$BCM_MULTIPASS_VM_NAME") ]]; then
  echo "Stopping multipass vm $BCM_MULTIPASS_VM_NAME"
  sudo multipass stop $BCM_MULTIPASS_VM_NAME
  sudo multipass delete $BCM_MULTIPASS_VM_NAME
  sudo multipass purge
else
  echo "$BCM_MULTIPASS_VM_NAME doesn't exist."
fi

# Removing lxc remote vm
if [[ $(lxc remote list | grep $BCM_MULTIPASS_VM_NAME) ]]; then
    echo "Removing lxd remote $BCM_MULTIPASS_VM_NAME"
    lxc remote set-default local
    lxc remote remove $BCM_MULTIPASS_VM_NAME
else
    echo "No lxc remote called $BCM_MULTIPASS_VM_NAME to delete."
fi

if [[ -d ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME ]]; then
  rm -rf ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME
fi

if [[ -d ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME/certs ]]; then
  rm -rf ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME/certs
fi

if [[ -d /tmp/bcm ]]; then
  rm -rf /tmp/bcm
fi

cd ~/.bcm
git add *
git commit -am "Removed ~/.bcm/clusters/$BCM_CLUSTER_NAME/$BCM_MULTIPASS_VM_NAME/"
cd -