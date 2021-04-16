output "jenkins_public_ip" {
  description = "public IP address of jenkins"
  value       = aws_instance.jenkins.public_ip
}


output "kube_control_public_ip" {
  description = "public IP address of kube_control"
  value       = aws_instance.kube_control.public_ip
}

output "kube_worker_public_ip" {
  description = "public IP address of kube_worker nodes"
  value       = aws_instance.kube_worker.*.public_ip
}