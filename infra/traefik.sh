#!/bin/bash

echo "[🚀] Launching Traefik installation via Helm..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace kube-system \
  -f traefik/values.yaml \
  --set service.port=9000

echo "[⏳] Waiting for the Traefik deployment to be ready..."
kubectl rollout status deployment traefik -n kube-system

echo "[🚀] Deploying Grafana..."
kubectl create namespace monitoring
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --set service.type=ClusterIP \
  --set service.port=3000

echo "[🛠️] Patch Traefik to expose the dashboards"
kubectl patch svc traefik -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/ports/-",
    "value": {
      "name": "traefik-dashboard",
      "port": 9000,
      "protocol": "TCP",
      "targetPort": 9000
    }
  }
]'

echo "[🌐] Applying Ingress rules for Jenkins, Grafana, and the Traefik dashboard..."
kubectl apply -f traefik/ingress.yaml

echo "[🛠️] Ensure local domains exist in /etc/hosts"
HOSTS_LINE="127.0.0.1 jenkins.local grafana.local traefik.local pgadmin.local"
NEEDED_DOMAINS=("jenkins.local" "grafana.local" "traefik.local" "pgadmin.local")
MISSING=()

for domain in "${NEEDED_DOMAINS[@]}"; do
  if ! grep -q "$domain" /etc/hosts; then
    MISSING+=("$domain")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "[⚠️] Missing entries in /etc/hosts: ${MISSING[*]}"
  echo "[🧰] Patching hosts file with local domain mappings..."

  # Remove any old conflicting entries
  sudo sed -i.bak '/127.0.0.1.*jenkins.local\|grafana.local\|traefik.local\|pgadmin.local/d' /etc/hosts

  # Add the correct clean line
  echo "$HOSTS_LINE" | sudo tee -a /etc/hosts > /dev/null
  echo "[✔️] Local host mappings added successfully."
else
  echo "[👌] Local domain names already configured."
fi

# Final message
echo "[🎉] All systems go! Setup complete."
echo "[🔗] Jenkins → http://jenkins.local"
echo "[🔗] Grafana → http://grafana.local"
echo "[🔗] Traefik → http://traefik.local"
echo "[🔗] pgAdmin → http://pgadmin.local"