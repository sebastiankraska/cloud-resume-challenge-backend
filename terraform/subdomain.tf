data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}

resource "aws_route53_record" "subdomain" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.subdomain_name}.${var.root_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.blog.domain_name # Changed from var
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}