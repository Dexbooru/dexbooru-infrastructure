
resource "aws_iam_user" "dexbooru_user_webapp" {
  name          = var.dexbooru_iam_user_name
  force_destroy = true
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

  statement {
    sid    = "AllowSQSAccess"
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      var.post_anime_series_queue_arn
    ]
  }
}


resource "aws_iam_user_policy" "dexbooru_user_webapp_policy" {
  name   = var.dexbooru_iam_user_policy_name
  user   = aws_iam_user.dexbooru_user_webapp.name
  policy = data.aws_iam_policy_document.dexbooru_user_webapp_document.json
}


resource "aws_iam_role" "sqs_poller_lambda_role" {
  name = "lambda-sqs-poller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "sqs_poller_lambda_logging" {
  role       = aws_iam_role.sqs_poller_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "sqs_poller_access_policy" {
  name = "sqs-poller-access"
  role = aws_iam_role.sqs_poller_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Effect   = "Allow",
        Resource = var.post_anime_series_queue_arn
      },
    ],
  })
}
