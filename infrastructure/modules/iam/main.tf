
resource "aws_iam_user" "dexbooru_user_webapp" {
  name          = var.dexbooru_iam_user_name
  force_destroy = true

  tags = {
    filepath = "infrastructure/modules/iam/main.tf"
  }
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
      "s3:PutObject",
      "s3:DeleteObject"
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

resource "aws_iam_user" "machine_learning_models" {
  name          = var.machine_learning_models_iam_user_name
  force_destroy = true

  tags = {
    filepath = "infrastructure/modules/iam/main.tf"
  }
}

data "aws_iam_policy_document" "anime_faces_captcha_challenges_document" {
  statement {
    sid    = "AllowAnimeFacesCaptchaChallengesBucketList"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]
  }

  statement {
    sid    = "AllowAnimeFacesCaptchaChallengesObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${var.anime_faces_captcha_challenges_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_user_policy" "anime_faces_captcha_challenges_policy" {
  name   = var.anime_faces_captcha_challenges_iam_user_policy_name
  user   = aws_iam_user.anime_faces_captcha_challenges.name
  policy = data.aws_iam_policy_document.anime_faces_captcha_challenges_document.json
}

resource "aws_iam_user" "anime_faces_captcha_challenges" {
  name          = var.anime_faces_captcha_challenges_iam_user_name
  force_destroy = true

  tags = {
    filepath = "infrastructure/modules/iam/main.tf"
  }
}


data "aws_iam_policy_document" "machine_learning_models_document" {
  statement {
    sid    = "AllowMachineLearningModelsBucketList"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      var.machine_learning_models_bucket_arn
    ]
  }

  statement {
    sid    = "AllowMachineLearningModelsObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${var.machine_learning_models_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_user_policy" "machine_learning_models_policy" {
  name   = var.machine_learning_models_iam_user_policy_name
  user   = aws_iam_user.machine_learning_models.name
  policy = data.aws_iam_policy_document.machine_learning_models_document.json
}

resource "aws_iam_user" "dexbooru_ai" {
  name          = var.dexbooru_ai_iam_user_name
  force_destroy = true

  tags = {
    filepath = "infrastructure/modules/iam/main.tf"
  }
}

resource "aws_iam_user_policy" "dexbooru_ai_machine_learning_models_policy" {
  name   = var.dexbooru_ai_iam_user_policy_name
  user   = aws_iam_user.dexbooru_ai.name
  policy = data.aws_iam_policy_document.machine_learning_models_document.json
}

resource "aws_iam_access_key" "dexbooru_ai" {
  user = aws_iam_user.dexbooru_ai.name
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

  tags = {
    filepath = "${path.module}/main.tf"
  }
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
