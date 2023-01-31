#!/bin/sh


read -p "Enter Flussonic license key: "  license_key

doctl kubernetes cluster create dynamic-03 --count 6 --region ams3
kubectl create secret generic flussonic-license --from-literal=license_key="${license_key}"


# DSN=$(doctl databases create dynamic-03 --engine mongodb --region ams3 --version 5.0 -o json|jq -r '.[0].connection.uri' )
# kubectl create secret generic mongo-logging --from-literal=dsn="${DSN}"

# For now we will use ephemeral mongodb. No need to spend time and money for real database
kubectl create secret generic mongo-logging --from-literal=dsn="mongodb://flus:sonic@mongo.default.svc.cluster.local:27017/flussonic?authSource=admin"


kubectl apply -f ../../lib/log2mongo/daemonset.yaml
exit 0
kubectl apply -f 00-secrets.yaml
kubectl apply -f 01-mongo.yaml
kubectl apply -f 01-konfig.yaml
kubectl apply -f 02-publish.yaml
kubectl apply -f 03-transcoder.yaml
kubectl apply -f 04-restreamer.yaml
