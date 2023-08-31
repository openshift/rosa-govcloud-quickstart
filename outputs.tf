output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = [for subnet in aws_subnet.rosa_private : subnet.id]
}

output "private_key" {
  value     = tls_private_key.jumphost_key.private_key_pem
  sensitive = true
}