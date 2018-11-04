provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/cidrs/terraform.tfstate"
    region = "us-east-1"
  }
}

/* ------------------ 192.168.0.0 ------------------ */

/* ADMIN VPN */
output "admin_vpn_c" {
  value = "192.168.0.0/28"
}

output "admin_vpn_e" {
  value = "192.168.0.16/28"
}

/* DEV VPN */
output "user_vpn_c" {
  value = "192.168.0.32/28"
}

/* LDAP */
output "ldap_c" {
  value = "192.168.0.48/28"
}

output "ldap_e" {
  value = "192.168.0.64/28"
}

/* ETCD */
output "etcd_b" {
  value = "192.168.0.80/28"
}

output "etcd_c" {
  value = "192.168.0.96/28"
}

output "etcd_d" {
  value = "192.168.0.112/28"
}

output "etcd_e" {
  value = "192.168.0.128/28"
}

output "etcd_f" {
  value = "192.168.0.144/28"
}

/* VAULT */
output "vault_b" {
  value = "192.168.0.160/28"
}

output "vault_c" {
  value = "192.168.0.176/28"
}

output "vault_d" {
  value = "192.168.0.192/28"
}

output "vault_e" {
  value = "192.168.0.208/28"
}

output "vault_f" {
  value = "192.168.0.224/28"
}

/* GITEA */
output "gitea_c" {
  value = "192.168.0.240/28"
}

/* ------------------ 192.168.1.0 ------------------ */
/* HARBOR */
output "harbor_c" {
  value = "192.168.1.0/28"
}

/* CONCOURSE */
output "concourse_c" {
  value = "192.168.1.16/28"
}

/* PROMETHEUS */
output "prometheus_c" {
  value = "192.168.1.32/28"
}

/* GRAFANA */
output "grafana_c" {
  value = "192.168.1.48/28"
}

/* FLUENTD */
output "fluentd_c" {
  value = "192.168.1.64/28"
}

/* KIBANA */
output "kibana_c" {
  value = "192.168.1.80/28"
}

/* ADMIN REVERSE WEB PROXY */
output "admin_proxy_c" {
  value = "192.168.1.96/28"
}

/* USER REVERSE WEB PROXY */
output "user_proxy_c" {
  value = "192.168.1.112/28"
}

/* INTERNET GATEWAY */
output "igw" {
  value = "192.168.1.128/28"
}

output "elasticsearch_c" {
  value = "192.168.1.144/28"
}

output "etcd_lb" {
  value = "192.168.1.160/28"
}

output "kube_master_c" {
  value = "192.168.1.176/28"
}

#output "" {
#  value = "192.168.1.192/28"
#}
#output "" {
#  value = "192.168.1.208/28"
#}
#output "" {
#  value = "192.168.1.224/28"
#}
#output "" {
#  value = "192.168.1.240/28"
#}

/* KUBELETS */
output "kubelets_c" {
  value = "192.168.2.0/26"
}

output "kubelets_e" {
  value = "192.168.2.64/26"
}

output "kubelets_f" {
  value = "192.168.2.128/26"
}

output "concourse_workers_c" {
  value = "192.168.2.192/26"
}

/* ------------------ 192.168.2.0 ------------------ */

