terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "2.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"  # Ensure this points to your cluster
}

provider "grafana" {
  url  = "http://grafana.local"
  auth = "admin:${var.grafana_password}"
}