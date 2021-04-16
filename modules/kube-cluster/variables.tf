variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used in resource names and tags."
  type        = string
}

variable "my_ip_list" {
  description = "List of my IPs"
  type        = list(string)
}

variable "worker_nodes_num" {
  description = "Number of Worker nodes in Kubernetes cluster"
  type        = number
}