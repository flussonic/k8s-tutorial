#!/bin/sh

read -p "Enter Flussonic license key: "  license_key

minikube start -n 3

kubectl create secret generic flussonic-license --from-literal=license_key="${license_key}"


# Reduce number of replicas to 1 for minikube

kubectl apply -f ./00-secrets.yaml
cat 01-publish-lb.yaml | 
  sed 's/replicas: 2/replicas: 1/' |
  sed "s/- port: 80/- port: 20080/"|
  sed "s/- port: 1935/- port: 21935/" |  kubectl apply -f -
cat 02-transcoder.yaml  | sed 's/replicas: 2/replicas: 1/' | kubectl apply -f -
cat 03-restreamer.yaml |
  sed 's/replicas: 2/replicas: 1/' | 
  sed "s/- port: 80/- port: 20180/" |
  kubectl apply -f -


