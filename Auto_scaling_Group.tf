# Creating auto scaling group
resource "aws_autoscaling_group" "asg" {
    vpc_zone_identifier = aws_subnet.private_sub[*].id #Setting the ASG in private subnets for security purpose
    name = "${var.project}-asg"
    max_size = 4
    min_size = 2
    desired_capacity = 2
    health_check_type = "ELB"
    termination_policies = ["OldestInstance"]
    target_group_arns = [aws_alb_target_group.apache-tg.arn]
    launch_template {
      id = aws_launch_template.web.id
      version = "$Latest"

    }
    tag {
      key = "Name"
      value = "${var.project}-web"
      propagate_at_launch = true
    }
    


  
}

# Creating a scaleout policy
resource "aws_autoscaling_policy" "apache_policy_up" {
    name = "${var.project}-scale-up"
    scaling_adjustment = 1 # How many Vms you want to be add when the scaling policy is triggered
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.asg.name

}
# Creating a scalein policy 
resource "aws_autoscaling_policy" "apache_policy_down" {
    name = "${var.project}-scale-down"
    scaling_adjustment = -1 # Remove 1 instance at a time to avoid aggressive scale-in 
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.asg.name
}

# Creating Cloudwatch alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
    alarm_name = "${var.project}-high-cpu"
    threshold = "70"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2" 
    period = "120"
    metric_name = "CPUUtilization"
    statistic = "Average"
    namespace = "AWS/EC2"
    

    dimensions = {
      AutoscalingGroupName = aws_autoscaling_group.asg.name
    }

    alarm_description = "This alarm monitors asg cpu utilization is > 70%"
    alarm_actions = [aws_autoscaling_policy.apache_policy_up.arn]

  
}


resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name = "${var.project}-low-cpu"
  threshold = "30"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 2
  period = 120
  metric_name = "CPUUtilization"
  statistic = "Average"
  namespace = "AWS/EC2"

  dimensions = {
      AutoscalingGroupName = aws_autoscaling_group.asg.name
    }

    alarm_description = "This alarm monitors asg cpu utilization is < 30%"
    alarm_actions = [aws_autoscaling_policy.apache_policy_down.arn]

  
}

