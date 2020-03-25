#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

## Delete anything that's tied to a project
for project in $(lxc query "/1.0/projects?recursion=1" | jq .[].name -r); do
    echo "==> Deleting all containers for project: ${project}"
    for container in $(lxc query "/1.0/containers?recursion=1&project=${project}" | jq .[].name -r); do
        lxc delete --project "${project}" -f "${container}"
    done
    
    if [[ $ALL_FLAG == 1 ]]; then
        for image in $(lxc query "/1.0/images?recursion=1&project=${project}" | jq .[].fingerprint -r); do
            FINGERPRINT=${image:0:12}
            #if lxc image list --format csv --columns lf | grep "$FINGERPRINT" | grep -q "bcm-lxc-base"; then
            echo "==> Deleting image ${FINGERPRINT} for project: ${project}"
            lxc image delete --project "${project}" "${image}"
        done
    fi
done

for project in $(lxc query "/1.0/projects?recursion=1" | jq .[].name -r); do
    echo "==> Deleting all profiles for project: ${project}"
    for profile in $(lxc query "/1.0/profiles?recursion=1&project=${project}" | jq .[].name -r); do
        if [ "${profile}" = "default" ]; then
            printf 'config: {}\ndevices: {}' | lxc profile edit --project "${project}" default
            continue
        fi
        lxc profile delete --project "${project}" "${profile}"
    done
    
    if [ "${project}" != "default" ]; then
        echo "==> Deleting project: ${project}"
        lxc project delete "${project}"
    fi
done

## Delete the networks
echo "==> Deleting all networks"
for network in $(lxc query "/1.0/networks?recursion=1" | jq '.[] | select(.managed) | .name' -r); do
    lxc network delete "${network}"
done

## Delete the storage pools
echo "==> Deleting all storage pools"
for storage_pool in $(lxc query "/1.0/storage-pools?recursion=1" | jq .[].name -r); do
    for volume in $(lxc query "/1.0/storage-pools/${storage_pool}/volumes/custom?recursion=1" | jq .[].name -r); do
        echo "==> Deleting storage volume ${volume} on ${storage_pool}"
        lxc storage volume delete "${storage_pool}" "${volume}"
    done
    
    ## Delete the custom storage volumes
    lxc storage delete "${storage_pool}"
done