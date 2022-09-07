Quickstart
==========



```
$ doctl auth init -t dop_v1_4e44.....
Using token [dop_v1_4e44....]

Validating token... OK



$ ./start.sh
Notice: Cluster is provisioning, waiting for cluster to be running
....................................................................
Notice: Cluster created, fetching credentials
Notice: Adding cluster credentials to kubeconfig file found in "/Users/max/.kube/config"
Notice: Setting current-context to do-ams3-publish-01
ID                                      Name          Region    Version        Auto Upgrade    Status     Node Pools
12345678-4170-4f44-825b-d55fa4321098    publish-01    ams3      1.24.4-do.0    false           running    publish-01-default-pool


$ kubectl apply -f publish.yaml 
serviceaccount/in-api-call-sa created
role.rbac.authorization.k8s.io/in-api-call-role created
rolebinding.rbac.authorization.k8s.io/in-api-call-rb created
configmap/streamer-presets created
secret/test-secret created
statefulset.apps/flussonic created
service/flussonic created


$ kubectl get service/flussonic
NAME        TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                       AGE
flussonic   LoadBalancer   10.245.165.235   <pending>     80:31626/TCP,1935:32726/TCP   3m32s

...


$ kubectl get service/flussonic
service/flussonic    LoadBalancer   10.245.165.235   132.45.123.101   80:31626/TCP,1935:32726/TCP   81m
```


open http://132.45.123.101/

```
./stop.sh
```

