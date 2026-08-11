output "vpc_id" {
  description = "ID of the cluster VPC."
  value       = aws_vpc.cluster.id
}

output "public_subnet_ids" {
  description = "IDs of the three public subnets, ordered by Availability Zone."
  value       = aws_subnet.public[*].id
}

output "node_security_group_id" {
  description = "Security group shared by all cluster nodes."
  value       = aws_security_group.nodes.id
}
