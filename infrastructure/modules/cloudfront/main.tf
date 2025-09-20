locals {
  s3_origins = var.s3_origins

  allowed_methods = ["GET", "HEAD"]
  cached_methods  = ["GET", "HEAD"]
  min_ttl         = 0
  default_ttl     = 3600
  max_ttl         = 86400
}

resource "aws_cloudfront_origin_access_identity" "default" {
  for_each = local.s3_origins
  comment  = "OAI for ${each.key}"
}

data "aws_iam_policy_document" "s3_policy" {
  for_each = local.s3_origins

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${each.value.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.default[each.key].iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "default" {
  for_each = local.s3_origins

  bucket = each.value.id
  policy = data.aws_iam_policy_document.s3_policy[each.key].json
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  for_each = local.s3_origins

  origin {
    domain_name = each.value.domain_name
    origin_id   = each.key

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default[each.key].cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Distribution for ${each.key}"

  default_cache_behavior {
    allowed_methods  = local.allowed_methods
    cached_methods   = local.cached_methods
    target_origin_id = each.key

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = local.min_ttl
    default_ttl            = local.default_ttl
    max_ttl                = local.max_ttl
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
