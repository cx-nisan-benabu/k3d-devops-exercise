#!/bin/bash

NAMESPACE="jenkins"

kubectl apply -f dsl/jenkins-worker-rbac.yaml

echo "[📘] Generating ConfigMaps for Job DSL initialization scripts..."
kubectl create configmap jenkins-init-dsl \
  --from-file=dsl/init.groovy \
  --from-file=dsl/job-dsl.groovy \
  -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "[🔧] Injecting DSL scripts into Jenkins StatefulSet..."
kubectl patch statefulset jenkins -n $NAMESPACE --type=json -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "jenkins-init-dsl",
      "configMap": {
        "name": "jenkins-init-dsl"
      }
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "jenkins-init-dsl",
      "mountPath": "/var/jenkins_home/init.groovy",
      "subPath": "init.groovy"
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "jenkins-init-dsl",
      "mountPath": "/var/jenkins_home/job-dsl.groovy",
      "subPath": "job-dsl.groovy"
    }
  }
]'

echo "[🔁] Rolling Jenkins StatefulSet to pick up new configuration..."
kubectl rollout restart statefulset jenkins -n $NAMESPACE
