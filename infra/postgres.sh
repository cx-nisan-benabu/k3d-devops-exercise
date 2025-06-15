#!/bin/bash

NAMESPACE="database"
SECRET_FILE="postgres/secret.yaml"
VALUES_FILE="postgres/values.yaml"
RELEASE_NAME="postgresql"
CHART_REPO="https://charts.bitnami.com/bitnami"
DB_NAME="devops"
TABLE_NAME="logs"

# Create namespace if it doesn't exist
echo "[📁] Creating database namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply secrets
echo "[🔐] Applying database secret..."
kubectl apply -f "$SECRET_FILE"

# Add Bitnami repo if not already added
if ! helm repo list | grep -q bitnami; then
    echo "[📦] Adding Bitnami Helm chart repo..."
    helm repo add bitnami "$CHART_REPO"
fi

echo "[🔄] Updating Helm repositories..."
helm repo update

# Deploy or upgrade PostgreSQL
echo "[🚀] Deploying PostgreSQL via Helm..."
helm upgrade --install "$RELEASE_NAME" bitnami/postgresql \
  --namespace "$NAMESPACE" \
  -f "$VALUES_FILE"

# Wait for StatefulSet to be ready
echo "[⏳] Waiting for PostgreSQL to become ready..."
kubectl rollout status statefulset/"$RELEASE_NAME" -n "$NAMESPACE"

# Display service info
kubectl get svc -n "$NAMESPACE"

# Extract PostgreSQL password from secret
echo "[🔑] Fetching PostgreSQL password from secret..."
POSTGRES_PASSWORD=$(kubectl get secret postgresql-secret -n "$NAMESPACE" -o jsonpath="{.data.postgres-password}" | base64 --decode)

# Create database if it doesn't exist
echo "[📁] Ensuring '$DB_NAME' database exists..."
kubectl run pg-client --rm -i --restart=Never --image=bitnami/postgresql --env="PGPASSWORD=$POSTGRES_PASSWORD" -- \
  psql -h postgresql.database.svc.cluster.local -U postgres -d postgres <<EOF
SELECT 'CREATE DATABASE $DB_NAME'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = '$DB_NAME'
)\gexec
EOF

# Create table if it doesn't exist
echo "[🧱] Creating '$TABLE_NAME' table in '$DB_NAME'..."
kubectl run pg-temp --rm -i --restart=Never --image=bitnami/postgresql --env="PGPASSWORD=$POSTGRES_PASSWORD" -- \
  psql -h postgresql.database.svc.cluster.local -U postgres -d "$DB_NAME" <<EOF
CREATE TABLE IF NOT EXISTS $TABLE_NAME (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Confirm schema
echo "[📊] Confirming tables in '$DB_NAME'..."
kubectl run pg-client --rm -i --restart=Never --image=bitnami/postgresql --env="PGPASSWORD=$POSTGRES_PASSWORD" -- \
  psql -h postgresql.database.svc.cluster.local -U postgres -d "$DB_NAME" <<EOF
\dt
EOF

# Enable pg_stat_statements extension (if not already created)
echo "[📈] Ensuring pg_stat_statements extension is enabled..."
kubectl run create-extension --rm -i --restart=Never --image=bitnami/postgresql \
  --env="PGPASSWORD=$POSTGRES_PASSWORD" -- \
  psql -h postgresql.database.svc.cluster.local -U postgres -d "$DB_NAME" \
  -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"


echo "[✅] PostgreSQL setup complete!"
