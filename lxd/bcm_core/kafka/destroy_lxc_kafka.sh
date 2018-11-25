#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

bash -c ./kafka_connect/destroy_kafka_connect.sh
bash -c ./kafka_rest/destroy_kafka_rest.sh
bash -c ./kafka_schema_registry/destroy_schema-registry.sh


# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    KAFKA_HOST="bcm-kafka-$(printf %02d "$HOST_ENDING")"
    ZOOKEEPER_STACK_NAME="zookeeper-$(printf %02d "$HOST_ENDING")"
    BROKER_STACK_NAME="broker-$(printf %02d "$HOST_ENDING")"

    # remove swarm services related to kafka
    if ! lxc list | grep -q "bcm-gateway-01"; then
        lxc exec bcm-gateway-01 -- docker stack rm "$BROKER_STACK_NAME" || true
        lxc exec bcm-gateway-01 -- docker stack rm "$ZOOKEEPER_STACK_NAME" || true


        for NODE_ID in $(lxc exec bcm-gateway-01 -- docker node list | grep "$KAFKA_HOST" | awk '{print $1;}'); do
            lxc exec bcm-gateway-01 -- docker node rm "$NODE_ID" --force
        done
    fi

    if [[ ! -z $(lxc list | grep "$KAFKA_HOST") ]]; then
        lxc delete "$KAFKA_HOST" --force
    fi


    if [[ ! -z $(lxc storage volume list "bcm_btrfs" | grep "$KAFKA_HOST-dockerdisk") ]]; then
        lxc storage volume delete "bcm_btrfs" "$KAFKA_HOST-dockerdisk" --target "$endpoint"
    fi
done

if lxc list | grep -q "bcm-gateway-01"; then
    if lxc exec bcm-gateway-01 -- docker network ls | grep -q kafkanet; then
        lxc exec bcm-gateway-01 -- docker network remove kafkanet
    fi


    if lxc exec bcm-gateway-01 -- docker network ls | grep -q zookeepernet; then
        lxc exec bcm-gateway-01 -- docker network remove zookeepernet
    fi
fi

if lxc profile list | grep -q "bcm_kafka_profile"; then
    lxc profile delete bcm_kafka_profile
fi
