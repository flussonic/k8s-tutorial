#!/bin/sh

doctl kubernetes cluster delete publish-lb-02


ingress_id=$(doctl compute load-balancer list -o json | jq -r '.[] | select (.name == "ingress-publish-lb-02") | .id')
egress_id=$(doctl compute load-balancer list -o json | jq -r '.[] | select (.name == "egress-publish-lb-02") | .id')
doctl compute load-balancer delete ${ingress_id}
doctl compute load-balancer delete ${egress_id}
