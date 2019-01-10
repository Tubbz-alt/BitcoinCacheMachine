#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

export BCM_ACTIVE=1

# shellcheck disable=SC1091
source ./.env

# let's set the local git client user and email settings to prevent error messages.
if [[ -z $(git config --get --global user.name) ]]; then
	git config --global user.name "bcm"
fi

if [[ -z $(git config --get --global user.email) ]]; then
	git config --global user.email "bcm@$(hostname)"
fi

# let's make sure the local git client is using TOR for git pull operations.
# this should have been configured on a global level already, but we'll set the local
# settings as well.
BCM_TOR_PROXY="socks5://localhost:9050"
if [[ $(git config --get --local http.proxy) != "$BCM_TOR_PROXY" ]]; then
	echo "Setting git client to use local SOCKS5 TOR proxy for push/pull operations."
	git config --local http.proxy "$BCM_TOR_PROXY"
fi

# get the current directory where this script is so we can set ENVs
echo "Setting BCM_GIT_DIR environment variable in current shell to '$(pwd)'"
BCM_GIT_DIR=$(pwd)
export BCM_GIT_DIR="$BCM_GIT_DIR"
export BCM_RUNTIME_DIR="$BCM_RUNTIME_DIR"

# commands in ~/.bashrc are delimited by these literals.
BCM_BASHRC_START_FLAG='###START_BCM###'
BCM_BASHRC_END_FLAG='###END_BCM###'
BASHRC_FILE="$HOME/.bashrc"

if grep -Fxq "$BCM_BASHRC_START_FLAG" "$BASHRC_FILE"; then
	# code if found
	echo "BCM flag discovered in '$BASHRC_FILE'. Please inspect your '$BASHRC_FILE' to clear any BCM-related content, if appropriate."
else
	echo "Writing commands to '$BASHRC_FILE' to enable the BCM CLI."
	{
		echo "$BCM_BASHRC_START_FLAG"
		echo "export BCM_GIT_DIR=$BCM_GIT_DIR"
		# shellcheck disable=SC2016
		echo "export PATH="'$PATH:'""'$BCM_GIT_DIR/cli'""
		echo "export BCM_ACTIVE=1"
		echo "export BCM_DEBUG=0"
		echo "$BCM_BASHRC_END_FLAG"
	} >>"$BASHRC_FILE"
fi

# make sure docker is installed. Doing it here makes sure we don't have to do it anywhere else.
bash -c "$BCM_GIT_DIR/cli/commands/install/snap_install_docker-ce.sh"

if ! dpkg-query -s encfs | grep -q "Status: install ok installed"; then
	echo "Installing encfs which encrypts data at rest."
	sudo apt-get install -y encfs

	if grep -q "#user_allow_other" </etc/fuse.conf; then
		# update /etc/fuse.conf to allow non-root users to specify the allow_root mount option
		sudo sed -i -e 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
	fi
fi

# TODO move this into the mgmtplan container rather than installing on host.
bash -c "$BCM_GIT_DIR/cli/commands/install/snap_lxd_install.sh"

sudo apt-get install -y wait-for-it

# let's ensure directories exist for bcm cli commands OUTSIDE of ~/.bcm
mkdir -p "$HOME/.gnupg"
mkdir -p "$HOME/.password_store"
mkdir -p "$HOME/.ssh"

echo "Done setting up your machine to use the Bitcoin Cache Machine CLI. Open a new terminal then type 'bcm --help'."
