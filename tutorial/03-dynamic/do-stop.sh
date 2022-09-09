#!/bin/sh


# mongo_id=$(doctl databases list -o json | jq '.[] | select (.name == "dynamic-03") | .id')
# doctl databases delete "${mongo_id}"

doctl kubernetes cluster delete dynamic-03

ingress_id=$(doctl compute load-balancer list -o json | jq -r '.[] | select (.name == "ingress-dynamic-03") | .id')
egress_id=$(doctl compute load-balancer list -o json | jq -r '.[] | select (.name == "egress-dynamic-03") | .id')
doctl compute load-balancer delete ${ingress_id}
doctl compute load-balancer delete ${egress_id}
