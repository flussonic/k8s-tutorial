#!/bin/bash


SA=/var/run/secrets/kubernetes.io/serviceaccount
NS=$(cat $SA/namespace)
TOKEN=$(cat $SA/token)
AUTH="Authorization: Bearer ${TOKEN}"
U="https://kubernetes.default.svc/api/v1/namespaces/$NS"

curl -sS --cacert $SA/ca.crt -H "$AUTH" "$U/pods?labelSelector=app=streamer" | \
  jq -c '.items | .[] | {name: .spec.nodeName, public: .status.hostIP, private: .status.podIP}' | while read spec; do
  NAME=$(echo $spec | jq -r .name)
  PUBLIC=http://$(echo $spec | jq -r .public)/
  PRIVATE=http://$(echo $spec | jq -r .private):81/
  echo "n: $NAME pub: ${PUBLIC}, priv: ${PRIVATE}"

  CLUSTER_KEY="FxNtj8tU0olsD1"
  APIKEY="apikey0"
  curl -sS \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${APIKEY}" \
    -X PUT \
    -d "{\"api_url\":\"${PRIVATE}\", \"public_payload_url\": \"${PUBLIC}\", \"cluster_key\": \"${CLUSTER_KEY}\"}" \
    http://central.default.svc.cluster.local/streamer/api/v3/streamers/${NAME}
done

