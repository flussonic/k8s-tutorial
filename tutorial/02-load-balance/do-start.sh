#!/bin/sh

set -ex

if [ -z "$LICENSE_KEY" ]; then
    read -p "Enter Flussonic license key: "  LICENSE_KEY
fi

doctl kubernetes cluster create publish-02 --count 6 --region ams3
kubectl create secret generic flussonic-license --from-literal=license_key="${LICENSE_KEY}"

kubectl get node --no-headers | sort | sed -n '1,2 p' | awk '{print $1}' | while read node; do
    kubectl label nodes $node cloud.flussonic.com/publish=true
done

kubectl get node --no-headers | sort | sed -n '3,4 p' | awk '{print $1}' | while read node; do
    kubectl label nodes $node cloud.flussonic.com/transcoder=true
done

kubectl get node --no-headers | sort | sed -n '5,6 p' | awk '{print $1}' | while read node; do
    kubectl label nodes $node cloud.flussonic.com/egress=true
done


kubectl apply -f ./00-secrets.yaml
kubectl apply -f ./01-publish.yaml
kubectl apply -f ./02-transcoder.yaml
kubectl apply -f ./03-restreamer.yaml


publish_ips=$(kubectl get node -l 'cloud.flussonic.com/publish=true' -o jsonpath="{.items[*].status.addresses[?(@.type=='ExternalIP')].address}")
for i in $publish_ips; do
    echo "Publish to rtmp://${i}/pub/streamname"
done

egress_ips=$(kubectl get node -l 'cloud.flussonic.com/egress=true' -o jsonpath="{.items[*].status.addresses[?(@.type=='ExternalIP')].address}")
for i in $egress_ips; do
    echo "Play from to http://${i}/pub/streamname/index.m3u8"
done
