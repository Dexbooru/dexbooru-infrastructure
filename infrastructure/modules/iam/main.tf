
resource "aws_iam_user" "dexbooru_user_webapp" {
  name          = var.dexbooru_iam_user_name
  force_destroy = true
}

resource "aws_iam_access_key" "dexbooru_user_webapp_access_key" {
  user = aws_iam_user.dexbooru_user_webapp.name
}

data "aws_iam_policy_document" "dexbooru_user_webapp_document" {
  statement {
    sid    = "AllowBucketList"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowBucketAccess"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      var.profile_picture_bucket_arn,
      var.post_picture_bucket_arn
    ]
  }

  statement {
    sid    = "AllowObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${var.profile_picture_bucket_arn}/*",
      "${var.post_picture_bucket_arn}/*",
      "${var.post_collection_picture_bucket_arn}/*"
    ]
  }
}


resource "aws_iam_user_policy" "dexbooru_user_webapp_policy" {
  name   = var.dexbooru_iam_user_policy_name
  user   = aws_iam_user.dexbooru_user_webapp.name
  policy = data.aws_iam_policy_document.dexbooru_user_webapp_document.json
}
