variable "root_domain" {
  description = "The root domain name, e.g. sebastiankraska.com"
  type        = string
  default     = "sebastiankraska.com"
}

variable "subdomain_name" {
  description = "The subdomain without the root domain, e.g. new"
  type        = string
  default     = "next"
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
  type = string
  default = "visitor-counter"
  description = "DynamoDB table name for visitor counter"
}