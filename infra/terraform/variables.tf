variable "cluster_name" {
  type    = string
  default = "sovereign-finops"
}

variable "metallb_ip_range" {
  description = "Plage d'IP pour le LoadBalancer MetalLB"
  type        = string
  default     = "172.18.255.200-172.18.255.250"
}
