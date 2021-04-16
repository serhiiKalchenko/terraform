# Initial 

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used in resource names and tags."
  type        = string
}

# Network

variable "vpc" {
  description = "VPC network"
  type        = string
}

variable "vpc_subnet" {
  description = "subnet of VPC"
  type        = string
}

variable "vpc_subnet_list" {
  description = "List of subnets"
  type        = list(string)
}

variable "ip_white_list" {
  description = "Allowed IP addresses"
  type        = list(string)
}

variable "my_ip_list" {
  description = "List of my IPs"
  type        = list(string)
}

# Instances (servers, nodes)

variable "jenkins_instance_type" {
  description = "instance type of Jenkins server"
  type        = string
}

variable "kube_instance_type" {
  description = "instance type of Jenkins server"
  type        = string
}

variable "jenkins_private_ip" {
  description = "private IP of Jenkins server"
  type        = string
}

variable "kube_control_private_ip" {
  description = "private IP of Kube Control node"
  type        = string
}

variable "worker_nodes_num" {
  description = "Number of Worker nodes in Kubernetes cluster"
  type        = number
}