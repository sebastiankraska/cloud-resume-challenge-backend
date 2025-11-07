resource "aws_cloudfront_origin_access_control" "blog" {
  name                              = "${var.subdomain_name}.${var.root_domain}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "blog" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  aliases = ["${var.subdomain_name}.${var.root_domain}"]


  # S3 origin (private bucket)
  origin {
    domain_name              = aws_s3_bucket.blog.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.blog.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.blog.id
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.blog.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600  # 1 hour
    max_ttl                = 86400 # 24 hours
    compress               = true
  }

  # Custom error responses (optional but good for SPAs)
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  # SSL certificate (requires ACM certificate - see next step)
viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.blog.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Geographic restrictions (optional)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "Blog CloudFront Distribution"
    Environment = "production"
  }
}