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
  type = string
  default = "cloudresumechallenge"
  description = "DynamoDB table name for Cloud Resume Challenge"
}