# ⚙️ Kubernetes DevOps Monitoring Stack

This project sets up a local Kubernetes environment with:

- **Jenkins** (with dynamic Kubernetes worker pods)
- **PostgreSQL** (secure and persistent)
- **Grafana** (with a live dashboard for PostgreSQL metrics)
- All services are exposed via **Traefik Ingress**

> Works on **K3d**.

---

## 🖼️ Architecture

![Architecture](./image.png)

---

## 📌 Project Goals

### 🧱 Part 1: Setup and Deployment

- Spin up a local Kubernetes cluster using **K3d**
- Install required tools: `kubectl`, `helm`, `docker`

### 🐘 Deploy PostgreSQL

- Helm-based PostgreSQL deployment
- Includes persistent volume + Kubernetes Secret for secure credentials

### 👷 Deploy Jenkins

- Jenkins with dynamic worker pods using the Kubernetes plugin
- HA deployment with persistent storage
- Jenkins DSL job runs every 5 minutes to insert a timestamp into PostgreSQL

---

### 🌐 Part 2: Traefik Ingress Controller

- **Traefik** acts as the load balancer and Ingress controller
- Routes external requests to:
  - Jenkins (`http://jenkins.local`)
  - Grafana (`http://grafana.local`)
  - Traefik dashboard (`http://traefik.local`)
- 📌 No port-forwarding is used

---

### 📊 Part 3: Monitoring with Grafana

- **Grafana** is deployed via Helm
- **Terraform** provisions a custom dashboard
- Dashboard shows:
  - CPU Usage
  - Memory Usage
  - PostgreSQL Transaction Throughput
  - Active Connections
  - Cache Hit Ratio

---

### 🖥️ Part 4: Deployment Script

A single Bash script installs or uninstalls the entire solution.

<!-- ```bash -->
./main.sh install    # Install everything
./main.sh uninstall  # Tear down everything

---

### 🔐 Accessing Grafana

You will need this password in two places:
- 🖥️ To log in to the [Grafana Dashboard](http://grafana.local)
- 🧹 To authenticate during the `terraform destroy` process

To retrieve the current admin password, run:

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
