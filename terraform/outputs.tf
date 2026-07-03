output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.blog.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.blog.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.blog.domain_name
}

output "website_url" {
  description = "Website URL"
  value       = "https://${var.root_domain}"
}

output "homelab_acme_access_key_id" {
  description = "Access key ID for the homelab ACME user (AWS_ACCESS_KEY_ID in homelab .env)"
  value       = aws_iam_access_key.homelab_acme.id
}

output "homelab_acme_secret_access_key" {
  description = "Secret access key for the homelab ACME user (AWS_SECRET_ACCESS_KEY in homelab .env)"
  value       = aws_iam_access_key.homelab_acme.secret
  sensitive   = true
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID (AWS_HOSTED_ZONE_ID in homelab .env)"
  value       = data.aws_route53_zone.main.zone_id
}