# Digitalocean quickstart

This part will describe how to launch quick tutorial on digitalocean.

This part will use managed kubernetes that is launched and managed by Digitalocean.

## Authorize on Digitalocean

1. Visit https://cloud.digitalocean.com/account/api/tokens
2. Create new token, i.e. `flussonic-k8s-tutorial`


```
$ doctl auth init -t dop_v1_4e44.....
Using token [dop_v1_4e44....]

Validating token... OK

```

## Launch managed service

Change content of LICENSE_KEY variable to your one or just omit it and script will ask you for the license key.

```
$ LICENSE_KEY="l4|...." ./do-start.sh
Notice: Cluster is provisioning, waiting for cluster to be running
....................................................................
Notice: Cluster created, fetching credentials
Notice: Adding cluster credentials to kubeconfig file found in "/Users/max/.kube/config"
Notice: Setting current-context to do-ams3-publish-01
ID                                      Name          Region    Version        Auto Upgrade    Status     Node Pools
12345678-4170-4f44-825b-d55fa4321098    publish-01    ams3      1.24.4-do.0    false           running    publish-01-default-pool
secret/flussonic-license created
serviceaccount/in-api-call-sa created
role.rbac.authorization.k8s.io/in-api-call-role created
rolebinding.rbac.authorization.k8s.io/in-api-call-rb created
configmap/streamer-presets created
secret/test-secret created
statefulset.apps/flussonic created
service/publish-01 created
```

Now need to check what is happening around:

```
$ kubectl get service/publish-01
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                       AGE
publish-01   LoadBalancer   10.245.182.249   <pending>     80:31385/TCP,1935:31217/TCP   2m22s
```

You can see `<pending>` under `EXTERNAL-IP`, it means that it is not ready yet. Wait a bit and periodically check what is happening.



```
$ kubectl get service/publish-01
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                       AGE
publish-01   LoadBalancer   10.245.182.249   138.68.123.27   80:31385/TCP,1935:31217/TCP   3m8s
```


open http://138.68.123.27/

You login and password are  `root` and `password`. 

## Cleanup

Now delete everything and clean it.

```
$ ./do-stop.sh 
serviceaccount "in-api-call-sa" deleted
role.rbac.authorization.k8s.io "in-api-call-role" deleted
rolebinding.rbac.authorization.k8s.io "in-api-call-rb" deleted
configmap "streamer-presets" deleted
secret "test-secret" deleted
statefulset.apps "flussonic" deleted
service "publish-01" deleted
Warning: Are you sure you want to delete this Kubernetes cluster? (y/N) ? y
Notice: Cluster deleted, removing credentials
Notice: Removing cluster credentials from kubeconfig file found in "/Users/max/.kube/config"
Notice: The removed cluster was set as the current context in kubectl. Run `kubectl config get-contexts` to see a list of other contexts you can use, and `kubectl config set-context` to specify a new one.
```



# Local multipass quickstart

You can launch several instances of virtual machines with `multipass` manager (very convenient MacOS VM management tool) and test k3s kubernetes management system.

```
$ LICENSE_KEY="l4|...." ./mp-start.sh
+ '[' -z 'l4|...' ']'
+ multipass launch --name k3s --cpus 1 --mem 1024M --disk 5G focal
Launched: k3s                                                                   
+ multipass launch --name pub1 --cpus 1 --mem 1024M --disk 5G focal             
Launched: pub1                                                                  
+ multipass exec k3s -- sudo /bin/sh -c 'curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -'
[INFO]  Finding release for channel stable
[INFO]  Using v1.25.6+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.25.6+k3s1/sha256sum-arm64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.25.6+k3s1/k3s-arm64
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s
++ multipass exec k3s sudo cat /var/lib/rancher/k3s/server/node-token
+ token=K107d45cbe8a5a92d120c51847d1633626818ac5cc47e7e1f0294f99d16a507dc3b::server:06dae9c0a69b6383b1c1389686dc96dc
++ multipass info k3s
++ grep -i ip
++ awk '{print $2}'
+ plane_ip=192.168.64.72
+ multipass exec pub1 -- sudo /bin/sh -c 'curl -sfL https://get.k3s.io | K3S_URL=https://192.168.64.72:6443 K3S_TOKEN=K107d45cbe8a5a92d120c51847d1633626818ac5cc47e7e1f0294f99d16a507dc3b::server:06dae9c0a69b6383b1c1389686dc96dc sh -'
[INFO]  Finding release for channel stable
[INFO]  Using v1.25.6+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.25.6+k3s1/sha256sum-arm64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.25.6+k3s1/k3s-arm64
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service.
[INFO]  systemd: Starting k3s-agent
+ multipass exec k3s sudo cat /etc/rancher/k3s/k3s.yaml
+ sed s/127.0.0.1/192.168.64.72/
++ pwd
+ export KUBECONFIG=/Users/max/Sites/k8s-tutorial/tutorial/01-publish/k3s.yaml
+ KUBECONFIG=/Users/max/Sites/k8s-tutorial/tutorial/01-publish/k3s.yaml
+ kubectl label nodes pub1 cloud.flussonic.com/publish=true
node/pub1 labeled
+ kubectl create secret generic flussonic-license '--from-literal=license_key=l4|e5t-IrB8JtDrFVikldVWq2|r6BzpmVPpjgKpn9IunpFp6lLbCZOp3'
secret/flussonic-license created
+ kubectl apply -f publish.yaml
serviceaccount/in-api-call-sa created
role.rbac.authorization.k8s.io/in-api-call-role created
rolebinding.rbac.authorization.k8s.io/in-api-call-rb created
configmap/streamer-presets created
secret/test-secret created
daemonset.apps/publish created
service/publish-01 created
++ multipass info pub1
++ grep -i ip
++ awk '{print $2}'
+ pub1_ip=192.168.64.73
+ echo 'Visit http://192.168.64.73/ server'
Visit http://192.168.64.73/ server
```

# Minikube setup

Minikube is a favourite all-in-one mechanism that allows to test your kubernetes installation. We recommend to use multipass + k3s on your laptop, but some people prefer minikube.

```
$ ./mk-start.sh
LICENSE_KEY="l4|..." ./mk-start.sh 
😄  minikube v1.26.0 on Darwin 11.5.2 (arm64)
🎉  minikube 1.29.0 is available! Download it: https://github.com/kubernetes/minikube/releases/tag/v1.29.0
💡  To disable this notice, run: 'minikube config set WantUpdateNotification false'

✨  Automatically selected the docker driver
📌  Using Docker Desktop driver with root privileges
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
💾  Downloading Kubernetes v1.24.1 preload ...
    > preloaded-images-k8s-v18-v1...: 342.86 MiB / 342.86 MiB  100.00% 24.93 Mi
🔥  Creating docker container (CPUs=2, Memory=4000MB) ...
🐳  Preparing Kubernetes v1.24.1 on Docker 20.10.17 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: default-storageclass, storage-provisioner
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
secret/flussonic-license created
serviceaccount/in-api-call-sa created
role.rbac.authorization.k8s.io/in-api-call-role created
rolebinding.rbac.authorization.k8s.io/in-api-call-rb created
configmap/streamer-presets created
secret/test-secret created
daemonset.apps/publish created
service/publish-01 created
|-----------|------------|-------------|---------------------------|
| NAMESPACE |    NAME    | TARGET PORT |            URL            |
|-----------|------------|-------------|---------------------------|
| default   | publish-01 | http/80     | http://192.168.49.2:32655 |
|           |            | rtmp/1935   | http://192.168.49.2:32310 |
|-----------|------------|-------------|---------------------------|
🏃  Starting tunnel for service publish-01.
|-----------|------------|-------------|------------------------|
| NAMESPACE |    NAME    | TARGET PORT |          URL           |
|-----------|------------|-------------|------------------------|
| default   | publish-01 |             | http://127.0.0.1:50201 |
|           |            |             | http://127.0.0.1:50202 |
|-----------|------------|-------------|------------------------|
[default publish-01  http://127.0.0.1:50201
http://127.0.0.1:50202]
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it.
```

Mention that on MacOS you need to leave this working to be able to access specified port.

Better use multipass.

```
./mk-stop.sh
```

will clean everything.
