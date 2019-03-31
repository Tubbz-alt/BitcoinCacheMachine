#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

CONTINUE=0
CHOICE=n

while [[ "$CONTINUE" == 0 ]]
do
    echo "WARNING: Are you sure you want to delete following directories:"
    echo ""
    echo " - $BCM_WORKING_DIR"
    echo " - $GNUPGHOME"
    echo " - $PASSWORD_STORE_DIR"
    echo " - $ELECTRUM_DIR"
    echo ""
    read -rp "Are you sure (y/n):  "   CHOICE
    
    if [[ "$CHOICE" == "y" ]]; then
        CONTINUE=1
        elif [[ "$CHOICE" == "n" ]]; then
        exit
    else
        echo "Invalid entry. Please try again."
    fi
done

# never delete GNUPGHOME UNLESS if the CLI is set to HOME/.gnupg (ie must be under ~/.bcm)

if [[ -d "$GNUPGHOME" ]]; then
    if [[ $GNUPGHOME != "$HOME/.gnupg" ]]; then
        if [[ "$CHOICE" == 'y' ]]; then
            if [ "$GNUPGHOME" != "$HOME/.gnupg" ]; then
                echo "Deleting $GNUPGHOME."
                rm -Rf "$GNUPGHOME"
            fi
        fi
    fi
else
    echo "WARNING: GNUPGHOME directory '$GNUPGHOME' does not exist. You may need to run 'bcm init'."
fi

if [[ -d "$PASSWORD_STORE_DIR" ]]; then
    if [[ "$CHOICE" == 'y' ]]; then
        if [ "$PASSWORD_STORE_DIR" != "$HOME/.password_store" ]; then
            echo "Deleting $PASSWORD_STORE_DIR."
            rm -Rf "$PASSWORD_STORE_DIR"
        fi
    fi
else
    echo "WARNING: PASSWORD_STORE_DIR directory '$PASSWORD_STORE_DIR' does not exist. You may need to run 'bcm init'."
fi

if [[ -d "$ELECTRUM_DIR" ]]; then
    if [[ "$CHOICE" == 'y' ]]; then
        if [ "$ELECTRUM_DIR" != "$HOME/.electrum" ]; then
            echo "Deleting $ELECTRUM_DIR."
            rm -Rf "$ELECTRUM_DIR"
        fi
    fi
else
    echo "WARNING: ELECTRUM_DIR directory '$ELECTRUM_DIR' does not exist. You may need to run 'bcm init'."
fi

if [[ -d "$BCM_SSH_DIR" ]]; then
    if [[ "$CHOICE" == 'y' ]]; then
        if [ "$BCM_SSH_DIR" != "$HOME/.ssh" ]; then
            echo "Deleting $BCM_SSH_DIR."
            rm -Rf "$BCM_SSH_DIR"
        fi
    fi
else
    echo "WARNING: BCM_SSH_DIR directory '$BCM_SSH_DIR' does not exist. You may need to run 'bcm init'."
fi

if [[ -d "$BCM_WORKING_DIR" ]]; then
    if [[ "$CHOICE" == 'y' ]]; then
        # TODO we will only delete this if the directroy is under RUNTIME_DIR
        echo "Deleting $BCM_WORKING_DIR."
        rm -Rf "$BCM_WORKING_DIR"
    fi
else
    echo "WARNING: BCM_WORKING_DIR directory '$BCM_WORKING_DIR' does not exist. You may need to run 'bcm init'."
fi

# # now let;s unmount the temp directory and remove the folders.
# encfs -u "$BCM_WORKING_DIR">>/dev/null

# if [[ -d "$BCM_WORKING_DIR" ]]; then
#     echo "Removing $BCM_WORKING_DIR"
#     rm -rf "$BCM_WORKING_DIR"
# fi

# if [[ -d "$BCM_WORKING_DIR""_enc" ]]; then
#     echo "Removing $BCM_WORKING_DIR""_enc"
#     rm -rf "$BCM_WORKING_DIR""_enc"
# fi
