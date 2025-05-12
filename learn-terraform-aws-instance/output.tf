output "file_kp_public-as2-001" {
  value       = tls_private_key.public_keypair.private_key_pem
  description = "Private key for the EC2 instance private"
  sensitive = true
}

output "file_kp_private-as2-001" {
  value       = tls_private_key.private_keypair.private_key_pem
  description = "Private key for the EC2 instance public"
  sensitive = true
}
