# Instances for Kubernetes cluster

provider "aws" {
  region = var.aws_region
}

# Creating a new Key Pair
resource "aws_key_pair" "kube" {

  # Name of the Key
  key_name = "kube_key"

  # Adding the SSH public key to authorized keys!
  public_key = file("~/.ssh/id_rsa.pub")

}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Provision instances for Kubernetes cluster

resource "aws_security_group" "kube_cluster" {
  name        = "Kube-cluster"
  description = "Allow ports: 22, all internal traffic"

  ingress {
    description = "22 port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.my_ip_list
  }

  ingress {
    description = "8080 port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.my_ip_list
  }

  ingress {
    description = "All internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Kube-cluster"
  }
}

resource "aws_instance" "kube_control" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.kube.key_name
  vpc_security_group_ids = [aws_security_group.kube_cluster.id]

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${self.tags.Name}"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
    }
  }

  tags = {
    Name    = "kube_control"
    Srv     = "kubernetes"
    Role    = "control"
    Project = var.project_name
  }
}

resource "aws_instance" "kube_worker" {
  count                  = var.worker_nodes_num
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.kube.key_name
  vpc_security_group_ids = [aws_security_group.kube_cluster.id]

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${self.tags.Name}"
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
    }
  }

  tags = {
    Name    = join("_", ["kube_worker", count.index + 1])
    Srv     = "kubernetes"
    Role    = "worker"
    Project = var.project_name
  }
}
