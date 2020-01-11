output "id" {
  description = "The instance ID"
  value       = aws_instance.polipo.id
}

output "arn" {
  description = "The ARN of the instance"
  value       = aws_instance.polipo.arn
}

output "private_ip" {
  description = "The private IP address assigned to the instance"
  value       = aws_instance.polipo.private_ip
}

output "private_dns" {
  description = "The private DNS name assigned to the instance"
  value       = aws_instance.polipo.private_dns
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable"
  value       = aws_instance.polipo.public_ip
}

output "public_dns" {
  description = "The public DNS name assigned to the instance"
  value       = aws_instance.polipo.public_dns
}
