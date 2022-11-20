resource "aws_cloudfront_distribution" "ghost" {


  enabled = true
  default_cache_behavior {

    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "apigw"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # cheaper
  price_class = "PriceClass_100"

  origin {
    domain_name = trimprefix(trimsuffix(aws_apigatewayv2_stage.ghost.invoke_url, "/"), "https://")
    origin_id   = "apigw"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]

    }
    # Note: doesn't seem to work; CloudFront strips this out
    #    custom_header {
    #      name  = "X-Forwarded-Proto"
    #      value = "https"
    #    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}