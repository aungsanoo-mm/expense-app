resource "aws_instance" "bastion" {
  ami                         = "ami-0b8607d2721c94a77"
  instance_type               = "t2.micro"
  key_name                    = var.ssh_key_name
  subnet_id                   = var.public_subnet_ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.bastion_sg_id]
  source_dest_check           = true
  tags = {
    Name = "Bastion-Host"
  }
}

# resource "aws_instance" "webapp_A" {
#   ami                    = "ami-0b8607d2721c94a77"
#   instance_type          = "t2.micro"
#   key_name               = var.ssh_key_name
#   subnet_id              = var.private_subnet_ids[0]
#   vpc_security_group_ids = [var.webapp_a_sg_id]
#   tags                   = { Name = "WebApp-A" }
#   user_data     = templatefile("${path.module}/web_app.sh", {
#     postgres_host     = var.rds_endpoint
#     postgres_port     = var.db_port
#     postgres_user = var.db_username
#     postgres_password = var.db_password
#     postgres_db       = var.db_name
#   })
# }

# resource "aws_instance" "webapp_B" {
#   ami                    = "ami-0b8607d2721c94a77"
#   instance_type          = "t2.micro"
#   key_name               = var.ssh_key_name
#   subnet_id              = var.private_subnet_ids[1]
#   vpc_security_group_ids = [var.webapp_b_sg_id]
#   tags                   = { Name = "WebApp-B" }
#     user_data     = templatefile("${path.module}/web_app.sh", {
#     postgres_host     = var.rds_endpoint
#     postgres_port     = var.db_port
#     postgres_user = var.db_username
#     postgres_password = var.db_password
#     postgres_db       = var.db_name
#   })
# }

# Launch Template for WebApp instances
resource "aws_launch_template" "webapp" {
  name_prefix   = "${var.vpc_name}-webapp-"
  image_id      = "ami-0b8607d2721c94a77" 
  instance_type = "t2.micro"
  key_name      = var.ssh_key_name

  # Network configuration
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.webapp_a_sg_id]
  }

  # User data script
  user_data = base64encode (
    templatefile("${path.module}/web_app.sh", {
      postgres_host     = var.db_address
      postgres_port     = var.db_port
      postgres_user     = var.db_username
      postgres_password = var.db_password
      postgres_db       = var.db_name
  })
  )

  # Block device mappings
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  # Tags
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.vpc_name}-webapp"
      Service = "webapp"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
##################################################################
# Autoscaling Group for WebApp instances
resource "aws_autoscaling_group" "webapp" {
  name_prefix         = "${var.vpc_name}-asg-"
  vpc_zone_identifier = var.private_subnet_ids

  # Launch Template configuration
  launch_template {
    id      = aws_launch_template.webapp.id
    version = "$Latest"
  }

  # Desired, minimum, maximum capacity
  desired_capacity          = 2
  min_size                  = 2
  max_size                  = 4
  health_check_grace_period = 300
  health_check_type         = "ELB" 

  # Target Group attachment for ALB
  target_group_arns = [var.target_group_arn]

  # Instance protection
  protect_from_scale_in = false

  # Tags
  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-webapp"
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "webapp"
    propagate_at_launch = true
  }

  # Ensure instances are spread across AZs
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }
}

