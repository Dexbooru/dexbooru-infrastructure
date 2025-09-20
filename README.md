# Dexbooru Infrastructure

Contains terraform configurations for deploying Dexbooru to AWS environment.

## Description

This repository contains the Terraform code to provision the necessary AWS infrastructure for the Dexbooru application. It sets up S3 buckets for storing images and an IAM user with specific permissions to access these buckets.

## Project Structure

All Terraform configuration is located within the `infrastructure/` directory.

- `main.tf`: The main entrypoint for the Terraform configuration. It defines the providers and calls the modules.
- `variables.tf`: Declares the variables used in the root module.
- `modules/`: This directory contains reusable Terraform modules.
  - `iam/`: Creates the IAM user and policy for the application.
    - `main.tf`: Defines the IAM user, access key, and policy.
    - `variables.tf`: Declares variables for the IAM module.
  - `s3/`: Creates the S3 buckets for storing images.
    - `main.tf`: Defines the S3 buckets.
    - `outputs.tf`: Defines outputs from the S3 module (e.g., bucket ARNs).
    - `variables.tf`: Declares variables for the S3 module.

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

3. **Configure AWS Region:**

   Create a `terraform.tfvars` file in the `infrastructure` directory with the following content, replacing `us-east-1` with your desired AWS region:

   ```terraform
   aws_region = "us-east-1"
   ```

4. **Initialize Terraform:**

   This will download the necessary providers.

   ```bash
   terraform init
   ```

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
