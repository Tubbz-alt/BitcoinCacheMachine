#!/bin/bash

set -eux

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Try 'sudo bash -c ./install.sh'"
    exit 1
fi

# get the codename, usually bionic or debian
CODE_NAME="$(< /etc/os-release grep VERSION_CODENAME | cut -d "=" -f 2)"

# add the tor apt repository
TOR_PROJECT_LINE="deb https://deb.torproject.org/torproject.org $CODE_NAME main"
TOR_PROJECT_LINE2="deb-src https://deb.torproject.org/torproject.org $CODE_NAME main"
if ! grep -Fxq "$TOR_PROJECT_LINE" /etc/apt/sources.list; then
    echo "$TOR_PROJECT_LINE" | tee -a /etc/apt/sources.list
fi

if ! grep -Fxq "$TOR_PROJECT_LINE2" /etc/apt/sources.list; then
    echo "$TOR_PROJECT_LINE2" | tee -a /etc/apt/sources.list
fi

# download the tor PGP key and add it as a trusted key to apt
gpg --import <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
sGsEejVHxvX7/iOE3rM=
=47bK
-----END PGP PUBLIC KEY BLOCK-----
EOF

gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

# update apt and install pre-reqs;
apt-get update

# remove any pre-existing software that may exist and have conflicts.
for PKG in lxd lxd-client tor; do
    if dpkg -s "$PKG" >/dev/null 2>&1; then
        apt-get remove "$PKG" -y
    fi
done

# remove any unused software.
apt-get autoremove -y

# reinstall required software.
apt-get install -y tor curl wait-for-it git deb.torproject.org-keyring iotop socat apg snapd openssh-server jq gnupg snapd sshfs

# upgrade all existing software.
sudo apt-get upgrade -y

# wait for local tor to come online.
wait-for-it -t 30 127.0.0.1:9050

# configure git to download through the local tor proxy.
BCM_GITHUB_REPO_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
git config --global http.$BCM_GITHUB_REPO_URL.proxy socks5://127.0.0.1:9050

# clone the BCM repo to /home/$SUDO_USER/bcm
SUDO_USER_HOME="/home/$SUDO_USER/Persistent"
BCM_GIT_DIR="$SUDO_USER_HOME/bcm"
export BCM_GIT_DIR="$BCM_GIT_DIR"
if [[ ! -d $BCM_GIT_DIR ]]; then
    git clone "$BCM_GITHUB_REPO_URL" "$BCM_GIT_DIR"
else
    cd "$BCM_GIT_DIR" && git pull
fi

# ensure the user owns the files.
chown -R "$SUDO_USER:$SUDO_USER" "$BCM_GIT_DIR"

cd "$BCM_GIT_DIR" && git checkout dev

# let's make sure the local git client is using TOR for git pull operations.
# this should have been configured on a global level already when the user initially
# downloaded BCM from github
BCM_TOR_PROXY="socks5://127.0.0.1:9050"
if [[ "$(git config --get --local http.$BCM_GITHUB_REPO_URL.proxy)" != "$BCM_TOR_PROXY" ]]; then
    echo "Setting git client to use local SOCKS5 TOR proxy for push/pull operations."
    git config --local "http.$BCM_GITHUB_REPO_URL.proxy" "$BCM_TOR_PROXY"
fi

# install LXD
if [[ ! -f "$(command -v lxc)" ]]; then
    # install lxd via snap
    # unless this is modified, we get snapshot creation in snap when removing lxd.
    echo "INFO: Installing 'lxd' on $HOSTNAME."
    snap install lxd --channel="candidate"
    snap set system snapshots.automatic.retention=no
    sleep 5
fi

# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    addgroup --system lxd
fi

# add the SUDO_USER user to the lxd group
if ! groups | grep -q lxd; then
    usermod -G lxd -a "$SUDO_USER"
fi

bash -c "$BCM_GIT_DIR/commands/cluster/cluster_create.sh"

# # if there's no group called lxd, create it.
# if ! groups "$(whoami)" | grep -q lxd; then
#     sudo gpasswd -a "$(whoami)" lxd
# fi

# TODO - update trusted PGP certificate.
# echo "GNUPGHOME: $GNUPGHOME"
# if ! gpg --list-keys | grep -q 94C6163354CB7A8CE5BABCDB36DB4B9E5F3E523C; then
#     echo "WARNING: the BCM public key will be imported into your local system. "
#     echo "INFO: bcm commands WILL NOT RUN unless you have explicitly trusted this key."
#     echo "INFO: run 'sudo gpg --import $BCM_GIT_DIR/PGP.txt' to import the BCM key."
#     exit
# fi

# configure SSH
mkdir -p "$SUDO_USER_HOME/.ssh"
if [[ ! -f "$SUDO_USER_HOME/.ssh/authorized_keys" ]]; then
    touch "$SUDO_USER_HOME/.ssh/authorized_keys"
    chown "$SUDO_USER:$SUDO_USER" -R "$SUDO_USER_HOME/.ssh"
fi

# this section configured the local SSH client on the Controller
# so it uses the local SOCKS5 proxy for any SSH host that has a
# ".onion" address. We use SSH tunneling to expose the remote onion
# server's LXD API and access it on the controller via a locally
# expose port (after SSH tunneling)
SSH_LOCAL_CONF="$SUDO_USER_HOME/.ssh/config"
if [[ ! -f "$SSH_LOCAL_CONF" ]]; then
    # if the .ssh/config file doesn't exist, create it.
    touch "$SSH_LOCAL_CONF"
fi


# Next, paste in the necessary .ssh/config settings for accessing
# remote LXD servers over TOR hidden services. This will make any 'ssh' command
# redirect all .onion hostnames to your localhost:9050 tor SOCKS5 proxy.
if [[ -f "$SSH_LOCAL_CONF" ]]; then
    SSH_ONION_TEXT="Host *.onion"
    if ! grep -Fxq "$SSH_ONION_TEXT" "$SSH_LOCAL_CONF"; then
        echo "Info (IMPORTANT): Updating your /etc/ssh/sshd_config file so it redirects all *.onion names out your local Tor proxy."
        {
            echo "$SSH_ONION_TEXT"
            echo "    ProxyCommand nc -xlocalhost:9050 -X5 %h %p"
        } >>"$SSH_LOCAL_CONF"
    fi
fi


# # add the current user to the sudoers
# sudo touch "/etc/sudoers.d/$SUDO_USER"
# echo "$SUDO_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "/etc/sudoers.d/$SUDO_USER"

# update /etc/ssh/sshd_config to listen for incoming SSH connections on all interfaces.
# TODO see if we can get this to listen on a specific interface rather than an IP address.
DEFAULT_ROUTE_INTERFACE="$(ip route | grep default | cut -d " " -f 5)"
IP_OF_DEFAULT_ROUTE_INTERFACE="$(ip addr show "$DEFAULT_ROUTE_INTERFACE" | grep "inet " | cut -d/ -f1 | awk '{print $NF}')"
if ! grep -Fxq "ListenAddress $IP_OF_DEFAULT_ROUTE_INTERFACE" /etc/ssh/sshd_config; then
    echo "ListenAddress $IP_OF_DEFAULT_ROUTE_INTERFACE" | tee -a /etc/ssh/sshd_config
fi


systemctl restart ssh
wait-for-it -t 15 "$IP_OF_DEFAULT_ROUTE_INTERFACE:22"
# end configure SSH
#####################

# install docker
snap install docker --channel="stable"

if ! grep -q docker /etc/group; then
    addgroup --system docker
fi

if ! groups "$SUDO_USER" | grep -q docker; then
    adduser $SUDO_USER docker
fi

# next we need to determine the underlying file system so we can upload the correct daemon.json
DEVICE="$(df -h "$HOME" | grep ' /' | awk '{print $1}')"
FILESYSTEM="$(mount | grep "$DEVICE")"

DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/overlay_daemon.json"
if echo "$FILESYSTEM" | grep -q "btrfs"; then
    DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/btrfs_daemon.json"
    DEST_DAEMON_FILE="/var/snap/docker/current/config/daemon.json"
    echo "INFO: Setting dockerd daemon settings to $DEST_DAEMON_FILE"
    cp "$DAEMON_CONFIG" "$DEST_DAEMON_FILE"
    snap restart docker
fi


BASHRC_FILE="/home/$SUDO_USER/.bashrc"
BASHRC_TEXT="export PATH=$""PATH:$SUDO_USER_HOME/bcm"
source "$BASHRC_FILE"
if ! grep -qF "$BASHRC_TEXT" "$BASHRC_FILE"; then
    echo "$BASHRC_TEXT" | tee -a "$BASHRC_FILE"
fi

echo "WARNING: Please restart your computer before running any 'bcm' commands!"
