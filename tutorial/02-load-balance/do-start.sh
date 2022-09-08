#!/bin/sh


read -p "Enter Flussonic license key: "  license_key

doctl kubernetes cluster create publish-lb-02 --count 6 --region ams3
kubectl create secret generic flussonic-license --from-literal=license_key="${license_key}"

kubectl apply -f ./00-secrets.yaml
kubectl apply -f ./01-publish-lb.yaml
kubectl apply -f ./02-transcoder.yaml
kubectl apply -f ./03-restreamer.yaml


