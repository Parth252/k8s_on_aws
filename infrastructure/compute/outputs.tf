output "node_instance_ids" {
  description = "Instance IDs, keyed by node name. Use these with aws ssm start-session."
  value       = { for name, instance in aws_instance.node : name => instance.id }
}

output "node_private_ips" {
  description = "Private IP addresses, keyed by node name."
  value       = { for name, instance in aws_instance.node : name => instance.private_ip }
}
