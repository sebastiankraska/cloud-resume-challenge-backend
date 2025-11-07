resource "aws_cloudfront_function" "rewrite-to-indexhtml" {
  name = "rewrite-to-indexhtml"
  runtime = "cloudfront-js-2.0"
  comment = "rewrites requests for nested resources of a Hugo site, e.g. something.com/posts/ to something.com/posts/index.html - fixes 'Access Denied' behaviour on Hugo subpages"
  publish = true
  code = file("${path.module}/cloudfront-function_rewrite-to-indexhtml.js")
}
