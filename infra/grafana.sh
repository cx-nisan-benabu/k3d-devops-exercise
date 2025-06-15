#!/bin/bash

echo "[📊] Setting up Grafana with enhanced PostgreSQL dashboard..."

# Navigate to terraform directory
cd terraform

# Extract PostgreSQL password from Kubernetes secret
echo "[🔑] Retrieving PostgreSQL credentials..."
PG_PASSWORD_B64=$(kubectl get secret postgresql-secret -n database -o jsonpath="{.data.postgres-password}")

if [ -z "$PG_PASSWORD_B64" ]; then
    echo "[❌] Error: Could not retrieve PostgreSQL password from secret"
    exit 1
fi

PG_PASSWORD=$(echo "$PG_PASSWORD_B64" | base64 --decode)

if [ -z "$PG_PASSWORD" ]; then
    echo "[❌] Error: Failed to decode PostgreSQL password"
    exit 1
fi

echo "[🔧] Setting up Terraform variables..."
export TF_VAR_pg_password="$PG_PASSWORD"

# Check if Grafana service is ready
echo "[⏳] Waiting for Grafana service to be ready..."
kubectl rollout status deployment grafana -n monitoring --timeout=300s

# Get Grafana admin password for Terraform provider
echo "[🔑] Retrieving Grafana admin credentials..."
GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

if [ -z "$GRAFANA_PASSWORD" ]; then
    echo "[❌] Error: Could not retrieve Grafana admin password"
    exit 1
fi

export TF_VAR_grafana_password="$GRAFANA_PASSWORD"

# Initialize Terraform
echo "[🏗️] Initializing Terraform..."
terraform init

# Apply Terraform configuration
echo "[🚀] Deploying Grafana dashboard and datasource..."
terraform apply -auto-approve

if [ $? -eq 0 ]; then
    echo "[✅] Grafana dashboard successfully deployed!"
    echo "[📊] Enhanced PostgreSQL dashboard with Jenkins job monitoring is now available"
    echo ""
    echo "🔗 SERVICE ACCESS INFORMATION:"
    echo "════════════════════════════════════════════════════════════════"
    echo "📊 Grafana: http://grafana.local"
    echo "   👤 Username: admin"
    echo "   🔑 Password: $GRAFANA_PASSWORD"
    echo ""
    echo "🗃️  pgAdmin: http://pgadmin.local"
    echo "   👤 Email: admin@example.com"
    echo "   🔑 Password: admin123!"
    echo ""
    echo "🏗️  Jenkins: http://jenkins.local"
    echo "🌐 Traefik: http://traefik.local"
    echo "════════════════════════════════════════════════════════════════"
else
    echo "[❌] Error: Terraform deployment failed"
    exit 1
fi
