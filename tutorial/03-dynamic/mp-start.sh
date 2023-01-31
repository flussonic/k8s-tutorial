#!/bin/sh

set -ex

if [ -z "$LICENSE_KEY" ]; then
    read -p "Enter Flussonic license key: "  LICENSE_KEY
fi

multipass launch --name k3s --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name pub1 --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name pub2 --cpus 1 --mem 1024M --disk 5G focal

multipass launch --name tc1 --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name tc2 --cpus 1 --mem 1024M --disk 5G focal

multipass launch --name rs1 --cpus 1 --mem 1024M --disk 5G focal
multipass launch --name rs2 --cpus 1 --mem 1024M --disk 5G focal

multipass exec k3s -- sudo /bin/sh -c 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -'

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

kubectl label nodes pub1 cloud.flussonic.com/publish=true
kubectl label nodes pub2 cloud.flussonic.com/publish=true
kubectl label nodes tc1 cloud.flussonic.com/transcoder=true
kubectl label nodes tc2 cloud.flussonic.com/transcoder=true
kubectl label nodes rs1 cloud.flussonic.com/egress=true
kubectl label nodes rs2 cloud.flussonic.com/egress=true

kubectl create secret generic flussonic-license --from-literal=license_key="${LICENSE_KEY}"
kubectl create secret generic mongo-logging --from-literal=dsn="mongodb://flus:sonic@mongo.default.svc.cluster.local:27017/flussonic?authSource=admin"

kubectl apply -f ../../lib/log2mongo/daemonset.yaml
kubectl apply -f 00-secrets.yaml

#kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
#kubectl create -f 01-longhorn-pvc.yaml
#kubectl create -f 01-longhorn-pod.yaml

kubectl apply -f 01-mongo.yaml
kubectl apply -f 01-konfig.yaml
kubectl apply -f 02-publish.yaml
kubectl apply -f 03-transcoder.yaml
kubectl apply -f 04-restreamer.yaml


pub1_ip=$(multipass info pub1 | grep -i ip | awk '{print $2}')
pub2_ip=$(multipass info pub2 | grep -i ip | awk '{print $2}')

rs1_ip=$(multipass info rs1 | grep -i ip | awk '{print $2}')
rs2_ip=$(multipass info rs2 | grep -i ip | awk '{print $2}')

echo "Publish: http://${pub1_ip}/ http://${pub2_ip}/"
echo "Play: http://${rs1_ip}/ http://${rs2_ip}/"
