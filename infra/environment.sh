#!/bin/bash

echo "🛠️  Bootstrapping..."

command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update

for tool in docker kubectl helm k3d; do
command -v $tool >/dev/null || brew install ${tool/docker/"--cask docker"}
done

docker --version && kubectl version --client && helm version && k3d version
echo "✅ Ready."

echo "🚀 Creating cluster: $CLUSTER_NAME"

if k3d cluster list | grep -q "$CLUSTER_NAME"; then
echo "✅ Cluster $CLUSTER_NAME already exists. Skipping."
else
k3d cluster create $CLUSTER_NAME \
--agents 2 \
--port "80:80@loadbalancer" \
--port "443:443@loadbalancer" \
--port "9000:9000@loadbalancer"
fi

kubectl cluster-info
kubectl get nodes

echo "✅ Cluster ready."
