locals {
  allowed_methods = ["GET", "HEAD"]
  cached_methods  = ["GET", "HEAD"]

  min_ttl     = 0
  default_ttl = 3600
  max_ttl     = 86400
  record_ttl  = 60
}

resource "aws_cloudfront_origin_access_identity" "default" {
  for_each = var.s3_origins
  comment  = "OAI for ${each.key}"
}

data "aws_iam_policy_document" "s3_policy" {
  for_each = var.s3_origins
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
  for_each = var.s3_origins
  bucket   = each.value.id
  policy   = data.aws_iam_policy_document.s3_policy[each.key].json
}


resource "aws_cloudfront_function" "root_html" {
  name    = "dexbooru-root-html"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<EOT
function handler(event) {
  var r = event.request;
  if (r.uri === "/" || r.uri === "") {
    return {
      statusCode: 200,
      statusDescription: "OK",
      headers: {
        "content-type": { value: "text/html; charset=utf-8" },
        "cache-control": { value: "public, max-age=300" }
      },
      body: "<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Dexbooru CDN</title></head><body><h1>Dexbooru CDN</h1><p>OK</p></body></html>"
    };
  }
  return r;
}
EOT
}


resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Dexbooru CDN distribution"
  aliases         = [var.domain_name]

  dynamic "origin" {
    for_each = var.s3_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.key
      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.default[origin.key].cloudfront_access_identity_path
      }
    }
  }

  default_cache_behavior {
    allowed_methods  = local.allowed_methods
    cached_methods   = local.cached_methods
    target_origin_id = "posts"
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = local.min_ttl
    default_ttl            = local.default_ttl
    max_ttl                = local.max_ttl

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.root_html.arn
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/collections/*"
    target_origin_id = "collections"
    allowed_methods  = local.allowed_methods
    cached_methods   = local.cached_methods
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = local.min_ttl
    default_ttl            = local.default_ttl
    max_ttl                = local.max_ttl
  }

  ordered_cache_behavior {
    path_pattern     = "/profiles/*"
    target_origin_id = "profile_pictures"
    allowed_methods  = local.allowed_methods
    cached_methods   = local.cached_methods
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
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
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
