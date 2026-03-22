# Dexbooru Infrastructure

Terraform configuration for deploying Dexbooru on AWS.

## Description

This repository provisions AWS resources for the Dexbooru application: object storage and a CDN for media, a queue and Lambda-based image classification (Gemini), container registries for Lambda images, and IAM identities and roles for the web app, ML workflows, and the classifier.

The root module requires Terraform **≥ 1.9.0** and the **hashicorp/aws** provider **~> 6.13**. State uses the **S3 backend** (configured via `backend.tfbackend` at init time).

## Project Structure

Terraform lives under `infrastructure/`.

| Path | Role |
|------|------|
| `main.tf` | Provider, backend block, and module wiring |
| `variables.tf` | Root input variables |
| `terraform.tfvars` | Local variable values (do not commit secrets) |
| `backend.tfbackend` | Backend configuration passed to `terraform init -backend-config=...` |
| `modules/` | Reusable modules (documented below) |

## Modules

Modules are composed in `infrastructure/main.tf` roughly in this order: **S3** and **SQS** first; **CloudFront** and **IAM** depend on bucket and queue ARNs; **ECR** discovers Lambda image repos from disk; **Lambda** ties together ECR, IAM, SQS, and the CDN domain.

### `modules/s3`

Creates four S3 buckets (via `for_each`): profile pictures, post pictures, collection pictures, and machine learning models. Buckets use `force_destroy = true` for easier teardown in non-production scenarios.

| File | Purpose |
|------|---------|
| `main.tf` | `aws_s3_bucket` resources |
| `variables.tf` | Per-bucket name variables |
| `outputs.tf` | `s3_buckets` map: `id`, `arn`, `domain_name` per logical key (`profile_pictures`, `post_pictures`, `collection_pictures`, `machine_learning_models`) |

### `modules/sqs`

Creates a single standard queue for **post image anime series classification** messages (consumed by Lambda). Tunables include delay, retention, max message size, and visibility timeout (see `main.tf` locals).

| File | Purpose |
|------|---------|
| `main.tf` | `aws_sqs_queue.anime_series_classification_queue` |
| `variables.tf` | Queue name |
| `outputs.tf` | Queue ARN, URL, and name |

### `modules/cloudfront`

Fronts the S3 buckets with one **CloudFront distribution**: Origin Access Identity, per-bucket policies allowing CloudFront `s3:GetObject`, and path-based cache behaviors mapping URL prefixes (`posts/*`, `collections/*`, `profile-pictures/*`) to the right origin. Geo restriction is a **whitelist** (currently CA and US). Uses the default CloudFront certificate (HTTPS).

| File | Purpose |
|------|---------|
| `main.tf` | OAI, `aws_s3_bucket_policy`, `aws_cloudfront_distribution` |
| `variables.tf` | `s3_origins` map (bucket `id`, `domain_name`, `arn`) |
| `outputs.tf` | Distribution `id`, `arn`, `domain_name` |

### `modules/iam`

IAM for the web app, ML storage, the AI microservice, and the SQS-poller Lambda.

- **Web application IAM user**: inline policy for listing buckets, S3 list/get/put/delete on profile, post, and collection buckets (objects and list where defined), and `sqs:SendMessage` on the classification queue. No Terraform-managed access key (create keys in AWS if needed).
- **Machine learning models user**: read/write/list on the ML models bucket only.
- **Dexbooru AI user**: same ML bucket policy as above, plus a **managed access key** (secret is only available at key creation time in AWS).
- **Lambda execution role** (`lambda-sqs-poller-role`): trust for `lambda.amazonaws.com`, `AWSLambdaBasicExecutionRole`, and inline policy for `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes` on the classification queue.

| File | Purpose |
|------|---------|
| `main.tf` | Users, policies, access key (AI user), Lambda role and attachments |
| `variables.tf` | User and policy names, bucket and queue ARNs |
| `outputs.tf` | SQS poller role ARN/name, `dexbooru_ai_access_key_id` |

### `modules/ecr`

Creates one **ECR repository per Lambda package** discovered under `modules/lambda/lambda_code/`: any immediate subdirectory that contains a `marker.txt` file becomes a repository named `lambda-function-<directory-name>`. Scan on push is enabled; tags are mutable.

| File | Purpose |
|------|---------|
| `main.tf` | `aws_ecr_repository` (for_each) |
| `outputs.tf` | `lambda_ecr_repository_details` map: `arn`, `repository_url` per repo name |

Adding a new container-based Lambda starts with a new folder + `marker.txt` under `lambda_code/` so this module creates a matching repository.

### `modules/lambda`

Defines the **post image anime series classifier** as a container Lambda: image URI from ECR (`lambda-function-post-image-anime-series-classifier:latest`), SQS event source mapping with partial batch failure reporting, CloudWatch log group (1-day retention), and environment variables for CDN domain, Gemini API key, webhook URL/secret, and `ENVIRONMENT=production`.

| File | Purpose |
|------|---------|
| `main.tf` | `aws_lambda_function`, `aws_cloudwatch_log_group`, `aws_lambda_event_source_mapping` |
| `variables.tf` | Function name, queue ARN, IAM role ARN, ECR details map, CDN domain, Gemini and webhook settings |
| `lambda_code/` | Source and Dockerfile(s) for classifier images pushed to ECR |

The Lambda module does not declare outputs; consumers use AWS or the root stack as needed.

## Continuous deployment

Pushes to `main` that touch `infrastructure/**` run `.github/workflows/terraform-deploy.yml`: OIDC to AWS, generated `terraform.tfvars` (including secrets from the GitHub environment), `terraform init` with `backend.tfbackend`, then plan and apply.

## Prerequisites

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) installed
- An AWS account with credentials configured for Terraform to use.
- [pre-commit](https://pre-commit.com/#installation) installed
- [TFLint](https://github.com/terraform-linters/tflint) installed

## Tooling Setup

This repository includes an `install_tools.sh` script to help set up the required development tools. This script can install `terraform`, `pre-commit`, and `tflint`.

The script supports macOS (with Homebrew) and various Linux distributions (using `apt`, `pacman`, `dnf`, or `yum`).

To run the script, execute it from the root of the repository:

```bash
./install_tools.sh
```

You can customize the tool versions by setting environment variables before running the script (e.g., `TERRAFORM_VERSION=1.9.0 ./install_tools.sh`). The script uses the following variables:

- `PRE_COMMIT_VERSION`
- `TERRAFORM_VERSION`
- `TFLINT_VERSION`

## Code Quality

This project uses pre-commit hooks to ensure code quality and consistency. The configuration can be found in `.pre-commit-config.yaml`.

The following hooks are used:

- `terraform_fmt`: Ensures all Terraform code is formatted correctly.
- `terraform_validate`: Validates the syntax of the Terraform code.
- `terraform_tflint`: Lints the Terraform code to catch errors and enforce best practices.

To enable the pre-commit hooks, run the following command in the root of the repository:

```bash
pre-commit install
```

Once installed, these checks will run automatically before each commit.

## Setup Instructions

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Dexbooru/dexbooru-infrastructure.git
   cd dexbooru-infrastructure
   ```

2. **Navigate to the infrastructure directory:**

   All Terraform commands should be run from this directory.

   ```bash
   cd infrastructure
   ```

3. **Configure variables:**

   Create or edit `infrastructure/terraform.tfvars` with values for every variable in `variables.tf` (bucket names, IAM names, queue and Lambda names, `gemini_api_key`, `webhook_secret`, `anime_series_classifier_webhook_url`, and `aws_region`). Use placeholders for secrets in version control.

4. **Initialize Terraform:**

   Download providers and configure the remote backend. For a backend config file (as in CI):

   ```bash
   terraform init -backend-config=backend.tfbackend -reconfigure
   ```

   Your AWS credentials must be allowed to use the remote state settings in `backend.tfbackend` (S3 bucket, key, and locking as configured for that backend).

5. **Apply the configuration:**

   This will create the AWS resources.

   ```bash
   terraform apply
   ```

   You will be prompted to confirm the changes. Type `yes` to proceed.

## Cleanup

To destroy all the resources created by this configuration, run from within the `infrastructure` directory:

```bash
terraform destroy
```
