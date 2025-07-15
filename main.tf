terraform {
  required_providers {
    aws = {
     source = "hashicorp/aws"
     version = "5.0"
    }
  }
}

provider "aws" {
    region = "ap-southeast-1"
  
}
resource "aws_instance" "webapp" {
    ami = "ami-07b3f199a3bed006a"
    instance_type = "t2.micro"
    
  
}