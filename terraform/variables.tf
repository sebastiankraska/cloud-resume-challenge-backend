variable "root_domain" {
  description = "The root domain name, e.g. sebastiankraska.com"
  type        = string
  default     = "sebastiankraska.com"
}

variable "cloudfront_distribution_domain" {
  type    = string
  default = "d5bgek5t6ulkj.cloudfront.net"
}

variable "cloudfront_hosted_zone_id" {
  type    = string
  default = "Z2FDTNDATAQYW2"
}

variable "dynamo_table_name" {
  type        = string
  default     = "cloudresumechallenge"
  description = "DynamoDB table name for Cloud Resume Challenge"
}

variable "homelab_domain" {
  description = "Domain for homelab services; wildcard and apex A records point at the NAS"
  type        = string
  default     = "home.sebastiankraska.com"
}

variable "homelab_nas_ip" {
  description = "LAN IP of the Synology NAS (intentionally published in public DNS)"
  type        = string
  default     = "192.168.178.222"
}