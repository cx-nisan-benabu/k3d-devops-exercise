#!/bin/bash

NAMESPACE="database"

echo "[🔧] Deploying pgAdmin for PostgreSQL monitoring..."

# Apply ConfigMap first
echo "[📋] Applying pgAdmin ConfigMap..."
kubectl apply -f pgadmin/configmap.yaml

# Apply Deployment and Service
echo "[🚀] Deploying pgAdmin..."
kubectl apply -f pgadmin/deployment.yaml

# Wait for deployment to be ready
echo "[⏳] Waiting for pgAdmin to become ready..."
kubectl rollout status deployment/pgadmin -n $NAMESPACE

# Display service info
echo "[ℹ️] pgAdmin service information:"
kubectl get svc pgadmin -n $NAMESPACE

echo "[✅] pgAdmin setup complete!"
echo "[🔗] pgAdmin will be accessible at: http://pgadmin.local"
echo "[👤] Login credentials:"
echo "     Email: admin@example.com"
echo "     Password: admin123!"
echo "[🐘] PostgreSQL server should be pre-configured and ready to connect" 