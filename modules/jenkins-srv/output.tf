output "public_ip" {
  description = "output the instance of jenkins"
  value       = aws_instance.jenkins.public_ip
}
