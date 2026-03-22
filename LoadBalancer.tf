# Creating alb security group
resource "aws_security_group" "alb-sg" {
    name = "alb_security"
    description = "Security group for ALB"
    vpc_id = aws_vpc.main-vpc.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTP from anywhere"
    }

    egress  {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
         

    }

    tags = {
      Name = "${var.project}-alb-sg"
    }
}
# Creating alb
resource "aws_alb" "alb" {
    name = "${var.project}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb-sg.id]
    subnets = aws_subnet.public[*].id

    tags = {
      Name = "${var.project}-alb"
    }
  
}

# The target group and listener are linked together
# Creating target group
resource "aws_alb_target_group" "apache-tg" {
  name = "${var.project}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main-vpc.id

  health_check {
    enabled = true
    path = "/"
    port = 80
    healthy_threshold = 2
    interval = 30
    matcher = "200"
    timeout = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project}-tg"
  }
}

# Creating an alb listener. The listener tells the ALB what to do
resource "aws_alb_listener" "http_listener" {
    load_balancer_arn = aws_alb.alb.arn # I got this from the name of the Loadbalancer
    port = "80"
    protocol = "HTTP"
    default_action {
      target_group_arn = aws_alb_target_group.apache-tg.arn
      type = "forward"
    }
  
}

