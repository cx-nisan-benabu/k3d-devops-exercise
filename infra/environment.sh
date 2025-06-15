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
export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)
else
echo "🏗️  Creating new cluster..."
k3d cluster create $CLUSTER_NAME \
--agents 2 \
--port "80:80@loadbalancer" \
--port "443:443@loadbalancer" \
--port "9000:9000@loadbalancer"
export KUBECONFIG=$(k3d kubeconfig write $CLUSTER_NAME)
echo "✅ Cluster $CLUSTER_NAME created successfully"
fi

echo "⏳ Waiting for cluster to be ready..."
sleep 10  # Give cluster time to initialize

# Wait for nodes to be available with retries
for i in {1..30}; do
    if kubectl get nodes >/dev/null 2>&1; then
        echo "✅ Cluster nodes are accessible"
        break
    fi
    echo "⏳ Waiting for nodes... (attempt $i/30)"
    sleep 5
done

echo "ℹ️  Cluster info:"
kubectl cluster-info
kubectl get nodes

echo "✅ Cluster ready."