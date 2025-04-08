#!/bin/bash

set -e
export CLUSTER_NAME="devops-cluster"
export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)

ACTION=$1

if [[ "$ACTION" != "install" && "$ACTION" != "uninstall" ]]; then
  echo "Usage: $0 <install|uninstall>"
  exit 1
fi

if [ "$ACTION" == "install" ]; then
  ./infra/environment.sh
  ./infra/postgres.sh
  ./infra/jenkins.sh
  ./infra/dsl.sh
  ./infra/traefik.sh
  ./infra/grafana.sh
else
  cd terraform
  terraform destroy --auto-approve
  echo "🧨 Deleting K3d cluster..."
  k3d cluster delete devops-cluster
  echo "✅ Cluster deleted."
fi
