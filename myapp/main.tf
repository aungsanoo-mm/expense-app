terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "expense_app" {
  ami           = "ami-0b8607d2721c94a77"  # Ubuntu 22.04
  instance_type = "t2.micro"
  key_name      = local.key_name
  tags = {
    Name = "Webapp"
  }
 provisioner "remote-exec" {
  inline = [ "echo 'echo ssh for ready' " ]
  connection {
    type = "ssh"
    user = local.ssh_user
    private_key = file(local.private_key_path)
    host = aws_instance.expense_app.public_ip
  } 
 }
 provisioner "local-exec" {
  command = "ansible-playbook -i '${aws_instance.expense_app.public_ip},' --private-key  ${local.private_key_path} webserver.yaml"
   
 }
  vpc_security_group_ids = [aws_security_group.expense_new.id]
}

resource "aws_security_group" "expense_new" {
  name        = "expense-new"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # HTTP
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Optional Flask API
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
