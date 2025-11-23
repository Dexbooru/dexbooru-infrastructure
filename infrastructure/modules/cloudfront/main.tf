locals {
  allowed_methods = ["GET", "HEAD", "OPTIONS"]
  cached_methods  = ["GET", "HEAD"]
  min_ttl         = 0
  default_ttl     = 3600
  max_ttl         = 86400

  whitelisted_countries_cdn = ["CA", "US"]

  key_map = {
    posts              = "post_pictures"
    collections        = "collection_pictures"
    "profile-pictures" = "profile_pictures"
  }

  origins = {
    for origin_id, input_key in local.key_map :
    origin_id => var.s3_origins[input_key]
    if contains(keys(var.s3_origins), input_key)
  }

  path_map = {
    "posts/*"            = "posts"
    "collections/*"      = "collections"
    "profile-pictures/*" = "profile-pictures"
  }

  ordered_paths = {
    for path, origin_id in local.path_map :
    path => origin_id if contains(keys(local.origins), origin_id)
  }

  default_origin_id = length(keys(local.origins)) > 0 ? keys(local.origins)[0] : ""
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "Dexbooru CDN OAI"
}

data "aws_iam_policy_document" "s3_read" {
  for_each = var.s3_origins
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${each.value.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cdn_read" {
  for_each = var.s3_origins
  bucket   = each.value.id
  policy   = data.aws_iam_policy_document.s3_read[each.key].json
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Dexbooru CDN"
  default_root_object = ""

  dynamic "origin" {
    for_each = local.origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.key
      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = local.default_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = local.allowed_methods
    cached_methods         = local.cached_methods
    compress               = true
    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }
    min_ttl     = local.min_ttl
    default_ttl = local.default_ttl
    max_ttl     = local.max_ttl
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.ordered_paths
    iterator = path
    content {
      path_pattern           = path.key
      target_origin_id       = path.value
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = local.allowed_methods
      cached_methods         = local.cached_methods
      compress               = true
      forwarded_values {
        query_string = true
        cookies { forward = "none" }
      }
      min_ttl     = local.min_ttl
      default_ttl = local.default_ttl
      max_ttl     = local.max_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = local.whitelisted_countries_cdn
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    filepath = "infrastructure/modules/cloudfront/main.tf"
  }
}
