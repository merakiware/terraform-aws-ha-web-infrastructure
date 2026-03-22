# EC2 sg
resource "aws_security_group" "ec2-sg" {
    name_prefix ="${var.project}-ec2-sg"
    description = "Security group for EC2 instance"
    vpc_id = aws_vpc.main-vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.alb-sg.id]
        description = "Allow HTTP from ALB"
    }
  
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "${var.project}-ec2-sg"
    }
}

# Creating launch template 
resource "aws_launch_template" "web" {
    name_prefix = "${var.project}-apache_lt"
    description = "My apache launch template"
    image_id = var.ami
    instance_type = var.instance_type 

    network_interfaces {
      associate_public_ip_address = false
      security_groups = [aws_security_group.ec2-sg.id]
    }

    
    user_data = filebase64("Scripts/install_apache.sh")

    tag_specifications {
      resource_type = "instance"
      tags = {
        Name = "${var.project}-web"
      }
    }

  
}
