output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.cicd_eip.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_eip.cicd_eip.public_dns
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.cicd_postgres.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.cicd_postgres.port
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_eip.cicd_eip.public_ip}:5173"
}

output "api_url" {
  description = "URL to access the API"
  value       = "http://${aws_eip.cicd_eip.public_ip}:3000"
}
