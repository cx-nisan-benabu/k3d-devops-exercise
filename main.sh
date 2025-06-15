#!/bin/bash

set -e
export CLUSTER_NAME="devops-cluster"

ACTION=$1

if [[ "$ACTION" != "install" && "$ACTION" != "uninstall" ]]; then
  echo "Usage: $0 <install|uninstall>"
  exit 1
fi

if [ "$ACTION" == "install" ]; then
  ./infra/environment.sh
  ./infra/postgres.sh
  ./infra/pgadmin.sh
  ./infra/jenkins.sh
  ./infra/dsl.sh
  ./infra/traefik.sh
  ./infra/grafana.sh
else
  echo "🧨 Deleting K3d cluster and all services..."
  k3d cluster delete $CLUSTER_NAME
  
  echo "🧹 Cleaning up Terraform state..."
  cd terraform
  rm -f terraform.tfstate* .terraform.tfstate.lock.info
  
  echo "✅ Complete cleanup finished."
fi
