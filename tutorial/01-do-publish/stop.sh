#!/bin/sh

kubectl delete -f publish.yaml 

doctl kubernetes cluster delete publish-01 
