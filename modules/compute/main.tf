resource "aws_instance" "bastion" {
  ami                         = "ami-0b8607d2721c94a77"
  instance_type               = "t2.micro"
  key_name                    = var.ssh_key_name
  subnet_id                   = var.public_subnet_ids[0] # <— use *_ids
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.bastion_sg_id] # <— use *_id
}

resource "aws_instance" "webapp_A" {
  ami                    = "ami-0b8607d2721c94a77"
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [var.webapp_a_sg_id]
  tags                   = { Name = "WebApp-A" }
}

resource "aws_instance" "webapp_B" {
  ami                    = "ami-0b8607d2721c94a77"
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  subnet_id              = var.private_subnet_ids[1]
  vpc_security_group_ids = [var.webapp_b_sg_id]
  tags                   = { Name = "WebApp-B" }
}
