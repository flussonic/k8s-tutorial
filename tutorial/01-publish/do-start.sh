#!/bin/sh


read -p "Enter Flussonic license key: "  license_key

doctl kubernetes cluster create publish-01 --count 1 --region ams3
kubectl create secret generic flussonic-license --from-literal=license_key="${license_key}"

kubectl apply -f ./publish.yaml
