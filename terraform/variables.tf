# PostgreSQL Host and Database Variables
variable "pg_host" {
  default = "postgresql.database.svc.cluster.local:5432"
}

variable "pg_database" {
  default = "devops"
}

variable "pg_user" {
  default = "postgres"
}


variable "pg_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}