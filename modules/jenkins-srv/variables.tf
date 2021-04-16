variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Name of the project. Used in resource names and tags."
  type        = string
}

variable "ip_white_list" {
  description = "Allowed IP addresses"
  type        = list(string)
}

variable "my_ip_list" {
  description = "List of my IPs"
  type        = list(string)
}