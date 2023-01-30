#!/bin/sh


if [ -z "${LICENSE_KEY}" ]; then
    read -p "Enter Flussonic license key: "  LICENSE_KEY
fi

doctl kubernetes cluster create publish-01 --count 1 --region ams3
kubectl create secret generic flussonic-license --from-literal=license_key="${LICENSE_KEY}"

kubectl apply -f ./publish.yaml
