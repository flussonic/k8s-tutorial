#!/bin/sh

set -exu

if [ -z "$LICENSE_KEY" ]; then
    read -p "Enter Flussonic license key: "  LICENSE_KEY
fi

multipass launch --name k3s --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name pub1 --cpus 1 --mem 1024M --disk 5G focal

multipass exec k3s -- sudo /bin/sh -c 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -'

token=$(multipass exec k3s sudo cat /var/lib/rancher/k3s/server/node-token)
plane_ip=$(multipass info k3s | grep -i ip | awk '{print $2}')

multipass exec pub1 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"

multipass exec k3s sudo cat /etc/rancher/k3s/k3s.yaml |sed "s/127.0.0.1/${plane_ip}/" > k3s.yaml
export KUBECONFIG=`pwd`/k3s.yaml

# cp ~/.kube/config ~/.kube/config.bak && \
# KUBECONFIG=~/.kube/config:k3s.yaml kubectl config view --flatten > /tmp/config && \
# mv /tmp/config ~/.kube/config && \
# rm -f k3s.yaml

kubectl label nodes pub1 cloud.flussonic.com/publish=true

kubectl create secret generic flussonic-license --from-literal=license_key="${LICENSE_KEY}"


kubectl apply -f publish.yaml

pub1_ip=$(multipass info pub1 | grep -i ip | awk '{print $2}')

echo "Visit http://${pub1_ip}/ server"

