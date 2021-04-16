# Infrastructure with Network

provider "aws" {
  region = var.aws_region
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

# Creating a new Key Pair
resource "aws_key_pair" "main" {

  # Name of the Key
  key_name = "EPAM_Final_Project_key"

  # Adding the SSH public key to authorized keys!
  public_key = file("~/.ssh/id_rsa.pub")

}

################################
##Create private network space##
################################

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc

  # Enabling automatic hostname assigning
  enable_dns_hostnames = true

  tags = {
    Name = var.project_name
  }
}



# Create Subnet for our instances
resource "aws_subnet" "main" {

  depends_on = [aws_vpc.main]

  vpc_id = aws_vpc.main.id

  cidr_block = var.vpc_subnet

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true

  tags = {
    Name = var.project_name
  }
}

# Create Internet gateway
resource "aws_internet_gateway" "main" {

  depends_on = [
    aws_vpc.main,
    aws_subnet.main
  ]

  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.project_name
  }
}

# Create Route Table for access from Internet
resource "aws_route_table" "main" {

  depends_on = [
    aws_vpc.main,
    aws_internet_gateway.main
  ]

  vpc_id = aws_vpc.main.id

  # to enable connection from outside
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = var.project_name
  }
}

# Assign RT to our Subnet
resource "aws_route_table_association" "main" {
  depends_on = [
    aws_vpc.main,
    aws_subnet.main,
    aws_route_table.main
  ]

  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

### Jenkins ###

#Create Security Group for Jenkins instance
resource "aws_security_group" "jenkins" {

  depends_on = [
    aws_vpc.main,
    aws_subnet.main
  ]

  vpc_id = aws_vpc.main.id

  name        = "Jenkins"
  description = "Allow ports: 22, 8080, all internal traffic"

  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = var.my_ip_list
  }

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
    cidr_blocks = var.ip_white_list
  }

  ingress {
    description = "All internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.vpc_subnet_list
  }

  # any port from inside to outside allowed
  egress {
    description = "All ports any protocol"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins"
  }
}

resource "aws_instance" "jenkins" {

  depends_on = [
    aws_vpc.main,
    aws_subnet.main,
    aws_security_group.jenkins
  ]

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.jenkins_instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]

  private_ip = var.jenkins_private_ip

  # Set hostnames
  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${self.tags.Name}"
    ]
    connection {
      host        = aws_instance.jenkins.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
    }
  }

  tags = {
    Name    = "jenkins"
    Srv     = "jenkins"
    Role    = "jenkins_control"
    Project = var.project_name
  }
}

### kube-cluster ###

# Provision instances for Kubernetes cluster

resource "aws_security_group" "kube_cluster" {

  depends_on = [
    aws_vpc.main,
    aws_subnet.main
  ]

  vpc_id = aws_vpc.main.id

  name        = "Kube-cluster"
  description = "Allow ports: 22, 8080, all internal traffic"

  # Inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = var.my_ip_list
  }

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
    cidr_blocks = var.vpc_subnet_list
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

  depends_on = [
    aws_vpc.main,
    aws_subnet.main,
    aws_security_group.jenkins
  ]

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.kube_instance_type
  key_name      = aws_key_pair.main.key_name

  subnet_id  = aws_subnet.main.id
  private_ip = var.kube_control_private_ip

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
  count = var.worker_nodes_num
  ami   = data.aws_ami.ubuntu.id

  subnet_id = aws_subnet.main.id

  instance_type          = var.kube_instance_type
  key_name               = aws_key_pair.main.key_name
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
