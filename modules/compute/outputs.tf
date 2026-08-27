output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "autoscaling_group_name" {
  description = "Name of the web Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}
