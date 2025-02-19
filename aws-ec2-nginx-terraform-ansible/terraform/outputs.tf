# terraform/outputs.tf
output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "private_key_location" {
  value = "${var.key_name}.pem"
}
