output "control_public_ip" {
  description = "public IP address of kube_control"
  value       = aws_instance.kube_control.public_ip
}

output "worker_public_ip" {
  description = "public IP address of kube_worker nodes"
  value       = aws_instance.kube_worker.*.public_ip
}