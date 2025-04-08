#!/bin/bash

# Config
controller_ns="jenkins"
agents_ns="jenkins-workers"
release="jenkins"
chart_repo="https://charts.jenkins.io"
values_file="jenkins/values.yaml"
rbac_file="jenkins/rbac.yaml"

# Create namespaces if missing
for ns in "$controller_ns" "$agents_ns"; do
  kubectl get ns "$ns" &>/dev/null || kubectl create ns "$ns"
done

# Ensure Helm repo exists
helm repo add jenkins "$chart_repo" 2>/dev/null || true
helm repo update

# Apply RBAC for secret access
kubectl apply -f "$rbac_file"

# Deploy or upgrade Jenkins via Helm
helm upgrade --install "$release" jenkins/jenkins \
  -n "$controller_ns" \
  -f "$values_file"

# ✅ Duplicate the secret into the jenkins-workers namespace
echo "[🔄] Copying postgresql-secret to jenkins-workers namespace..."
kubectl get secret postgresql-secret -n default -o yaml \
  | sed "s/namespace: default/namespace: jenkins-workers/" \
  | kubectl apply -f -

# Wait for StatefulSet creation
until kubectl get statefulset "$release" -n "$controller_ns" &>/dev/null; do
  echo "Waiting for Jenkins StatefulSet..."
  sleep 4
done

# Wait for readiness
kubectl rollout status statefulset "$release" -n "$controller_ns"

# Output admin password
echo -e "\n🔐 Admin password:"
kubectl get secret "$release" -n "$controller_ns" -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
echo -e "\n"

# Optional: Print env vars related to PostgreSQL
echo "📦 POSTGRES env from Jenkins pod:"
jenkins_pod=$(kubectl get pods -n "$controller_ns" -l app.kubernetes.io/name=jenkins -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n "$controller_ns" -it "$jenkins_pod" -- printenv | grep POSTGRES || echo "(No POSTGRES env found)"
