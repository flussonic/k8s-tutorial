#!/bin/sh

set -exu

if [ -z "$license_key" ]; then
    read -p "Enter Flussonic license key: "  license_key
fi

multipass launch --name k3s --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name pub1 --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name pub2 --cpus 1 --mem 1024M --disk 5G focal

multipass launch --name tc1 --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name tc2 --cpus 1 --mem 1024M --disk 5G focal

multipass launch --name rs1 --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name rs2 --cpus 1 --mem 1024M --disk 5G focal




multipass exec k3s -- sudo /bin/sh -c 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -'
multipass exec k3s -- sudo /bin/sh -c "systemctl daemon-reload; systemctl restart k3s"


token=$(multipass exec k3s sudo cat /var/lib/rancher/k3s/server/node-token)
plane_ip=$(multipass info k3s | grep -i ip | awk '{print $2}')

multipass exec pub1 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"
multipass exec pub2 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"
multipass exec tc1 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"
multipass exec tc2 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"
multipass exec rs1 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"
multipass exec rs2 -- sudo /bin/sh -c "curl -sfL https://get.k3s.io | K3S_URL=https://${plane_ip}:6443 K3S_TOKEN=${token} sh -"

multipass exec k3s sudo cat /etc/rancher/k3s/k3s.yaml |sed "s/127.0.0.1/${plane_ip}/" > k3s.yaml
export KUBECONFIG=`pwd`/k3s.yaml

# cp ~/.kube/config ~/.kube/config.bak && \
# KUBECONFIG=~/.kube/config:k3s.yaml kubectl config view --flatten > /tmp/config && \
# mv /tmp/config ~/.kube/config && \
# rm -f k3s.yaml

kubectl label nodes pub1 cloud.flussonic.com/publish=true
kubectl label nodes pub2 cloud.flussonic.com/publish=true
kubectl label nodes tc1 cloud.flussonic.com/transcoder=true
kubectl label nodes tc2 cloud.flussonic.com/transcoder=true
kubectl label nodes rs1 cloud.flussonic.com/egress=true
kubectl label nodes rs2 cloud.flussonic.com/egress=true

kubectl create secret generic flussonic-license --from-literal=license_key="${license_key}"


kubectl apply -f 00-secrets.yaml
kubectl apply -f 01-publish.yaml
kubectl apply -f 02-transcoder.yaml
kubectl apply -f 03-restreamer.yaml



