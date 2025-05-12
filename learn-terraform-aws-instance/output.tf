output "file_kp_public-as2-001" {
  value       = tls_private_key.kp-private-as2-001.private_key_pem
  description = "Private key for the EC2 instance private"
}

output "file_kp_private-as2-001" {
  value       = tls_private_key.kp-private-as2-002.private_key_pem
  description = "Private key for the EC2 instance public"
}
