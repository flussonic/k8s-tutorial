#!/bin/sh

if [ -z "${LICENSE_KEY}" ]; then
    read -p "Enter Flussonic license key: "  LICENSE_KEY
fi

minikube start -n 1

kubectl create secret generic flussonic-license --from-literal=license_key="${LICENSE_KEY}"


kubectl apply -f ./publish.yaml

minikube service publish-01


