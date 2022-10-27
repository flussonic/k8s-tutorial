#!/bin/sh

kubectl delete -f publish.yaml 

doctl kubernetes cluster delete publish-01 

lb_id=$(doctl compute load-balancer list -o json | jq -r '.[] | select (.name == "publish-01") | .id')
doctl compute load-balancer delete ${lb_id}

