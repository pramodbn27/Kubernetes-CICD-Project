# configured aws provider with proper credentials
provider "aws" {
  region    = "us-east-1"
  
}


# create default vpc if one does not exit
resource "aws_vpc" "default_vpc" {
    cidr_block = "10.0.0.0/16"

  tags    = {
    Name  = "default_vpc"
  }
}



# create default subnet if one does not exit
resource "aws_subnet" "public_subnet-jenkins" {
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.default_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
   

  tags   = {
    Name = "jenkins-subnet"
  }
}

 #create default subnet if one does not exit
resource "aws_subnet" "public_subnet-ansible" {
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.default_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
    

  tags   = {
    Name = "ansible-subnet"
  }
}

#create default subnet if one does not exit
resource "aws_subnet" "public_subnet-minikube" {
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.default_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
    

  tags   = {
    Name = "minikube-subnet"
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.default_vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default_vpc.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.example.id
}

resource "aws_route_table_association" "public_jenkins" {
  subnet_id      = aws_subnet.public_subnet-jenkins.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_ansible" {
  subnet_id      = aws_subnet.public_subnet-ansible.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_minikube" {
  subnet_id      = aws_subnet.public_subnet-minikube.id
  route_table_id = aws_route_table.public.id
}



# create security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_vpc.default_vpc.id

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Custom TCP"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "ec2_security_group"
  }
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

  owners = ["099720109477"] # Canonical
}




# launch the ec2 instance and install website
resource "aws_instance" "jenkins-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet-jenkins.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "kafka-key"
  user_data              = file("jenkins-install.sh")

  tags = {
    Name = "jenkins_server"
  }
}


# print the ec2's public ipv4 address
output "public_ipv4_address" {
  value = aws_instance.jenkins-server.public_ip
}

resource "aws_instance" "ansible-server" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet-ansible.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "kafka-key"
  user_data              = file("ansible-install.sh")

  tags = {
    Name = "ansible_server"
  }
}


# print the ec2's public ipv4 address
output "public_ipv4_ansible" {
  value = aws_instance.ansible-server.public_ip
}

resource "aws_instance" "minikube-server" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_subnet-minikube.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "kafka-key"
  user_data              = file("minikube-install.sh")

  tags = {
    Name = "minikube_server"
  }
}


# print the ec2's public ipv4 address
output "public_ipv4_minikube" {
  value = aws_instance.minikube-server.public_ip
}