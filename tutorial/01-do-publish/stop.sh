#!/bin/sh

kubectl delete -f publish.yaml 

doctl kubernetes cluster delete publish-01 
doctl compute load-balancer delete publish-01
