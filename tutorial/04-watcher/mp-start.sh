#!/bin/sh

set -ex

if [ -f env ]; then
    set -a
    source ./env
    set +a
fi

if [ -z "$LICENSE_KEY" ]; then
    read -p "Enter Flussonic license key: "  LICENSE_KEY
fi

multipass launch --name manage --cpus 1 --memory 1024M --disk 5G focal
multipass launch --name streamer1 --cpus 1 --memory 1024M --disk 5G focal
multipass launch --name streamer2 --cpus 1 --memory 1024M --disk 5G focal

multipass exec manage -- sudo /bin/sh -c 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" INSTALL_K3S_VERSION="v1.25.11+k3s1" sh -'

token=$(multipass exec manage sudo cat /var/lib/rancher/k3s/server/node-token)
plane_ip=$(multipass info manage | grep -i ip | awk '{print $2}')

multipass exec streamer1 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"
multipass exec streamer2 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"

multipass exec manage sudo cat /etc/rancher/k3s/k3s.yaml |sed "s/127.0.0.1/${plane_ip}/" > k3s.yaml
export KUBECONFIG=`pwd`/k3s.yaml

kubectl label nodes manage watcher.flussonic.com/manage=true
kubectl label nodes streamer1 watcher.flussonic.com/streamer=true
kubectl label nodes streamer2 watcher.flussonic.com/streamer=true

kubectl create secret generic flussonic-license --from-literal=license_key="${LICENSE_KEY}"

kubectl apply -f 00-secrets.yaml
kubectl apply -f 01-postgres.yaml
kubectl apply -f 02-streamer.yaml
kubectl apply -f 03-central.yaml


watcher_ip=$(multipass info manage | grep -i ip | awk '{print $2}')

echo "Watcher: http://${watcher_ip}/"
