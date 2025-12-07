import hashlib
import json
import logging
import os
import subprocess
import sys
from types import NoneType
from typing import Dict, List, Optional, Tuple, TypedDict, Union
from venv import logger

import boto3


class LambdaConfig(TypedDict):
    language_extension: str
    source_code_folder: str
    package_files: List[str]
    dockerfile_sha256_hash: Optional[str]
    source_code_sha256_hash: Optional[str]
    package_files_sha256_hash: Optional[str]


LAMBDA_CODE_PATH = "../infrastructure/modules/lambda/lambda_code"


logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def read_lambda_config_file(filepath: str) -> LambdaConfig:
    with open(filepath, "r") as f:
        config = json.load(f)
    return LambdaConfig(**config)


def write_lambda_config_file(
    config_filepath: str, lambda_config: LambdaConfig
) -> NoneType:
    with open(config_filepath, mode="w") as file:
        file.write(json.dumps(lambda_config, indent=2))


def compute_hash_for_file(filepath: str) -> str:
    with open(filepath, mode="rb") as file:
        file_bytes = file.read()
        return hashlib.sha256(file_bytes).hexdigest()


def compute_sha256_of_lambda_src(
    lambda_config: LambdaConfig, lambda_folder_path: str
) -> Tuple[str, str, str]:
    lambda_source_extension = lambda_config.get("language_extension", "*")
    lambda_source_folder = lambda_config.get("source_code_folder", "src")
    lambda_source_folder_path = os.path.join(lambda_folder_path, lambda_source_folder)

    docker_filepath = os.path.join(lambda_folder_path, "Dockerfile")
    docker_ignore_filepath = os.path.join(lambda_folder_path, ".dockerignore")
    dockerfile_hash = compute_hash_for_file(docker_filepath) + compute_hash_for_file(
        docker_ignore_filepath
    )

    code_hash = ""
    for source_filename in os.listdir(lambda_source_folder_path):
        source_filename_path = os.path.join(lambda_source_folder_path, source_filename)
        if lambda_source_extension == "*":
            code_hash += compute_hash_for_file(source_filename_path)
        else:
            is_codefile = source_filename_path.endswith(lambda_source_extension)
            code_hash += (
                compute_hash_for_file(source_filename_path) if is_codefile else ""
            )

    package_files = lambda_config.get("package_files", [])
    package_file_hash = ""
    for package_file in package_files:
        package_filepath = os.path.join(lambda_folder_path, package_file)
        package_file_hash += compute_hash_for_file(package_filepath)

    return dockerfile_hash, code_hash, package_file_hash


def write_hashes_to_file(
    config_filepath: str,
    lambda_config: LambdaConfig,
    dockerfile_hash: str,
    source_code_hash: str,
    package_files_hash: str,
) -> None:
    lambda_config["dockerfile_sha256_hash"] = dockerfile_hash
    lambda_config["source_code_sha256_hash"] = source_code_hash
    lambda_config["package_files_sha256_hash"] = package_files_hash
    write_lambda_config_file(config_filepath, lambda_config)


def get_ecr_repositories() -> List[Dict]:
    ecr_repos = boto3.client("ecr")
    response = ecr_repos.describe_repositories()
    return [repo for repo in response["repositories"]]


def get_matching_ecr_repo(
    lambda_folder_path: str, ecr_repos: List[Dict]
) -> Union[Dict, None]:
    lambda_folder_name = lambda_folder_path.split("/")[-1]
    search_repo_name = f"lambda-function-{lambda_folder_name}"

    matching_repos = [
        repo for repo in ecr_repos if repo.get("repositoryName", "") == search_repo_name
    ]
    if len(matching_repos) == 0:
        return None

    return matching_repos[0]


def get_lambda_folder_paths() -> List[str]:
    lambda_folder_paths: List[str] = []

    for folder in os.listdir(LAMBDA_CODE_PATH):
        lambda_folder_path = os.path.join(LAMBDA_CODE_PATH, folder)
        lambda_folder_paths.append(lambda_folder_path)

    return lambda_folder_paths


def run_command(
    command: Union[str, List[str]], check_error: bool = True, stream_output: bool = False
) -> Tuple[bool, str]:
    try:
        if stream_output:
            result = subprocess.run(
                command,
                check=check_error,
                shell=isinstance(command, str),
                text=True,
            )
        else:
            result = subprocess.run(
                command,
                check=check_error,
                shell=isinstance(command, str),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
        success = result.returncode == 0
        if stream_output:
            return success, ""
        return success, result.stdout.strip()
    except subprocess.CalledProcessError as e:
        error_message = (
            f"Command failed with exit code {e.returncode}:\n"
            f"STDOUT:\n{e.stdout}\n"
            f"STDERR:\n{e.stderr}"
        )
        return False, error_message
    except FileNotFoundError:
        return (
            False,
            "Command not found. Ensure required tools (docker/aws) are installed and in PATH.",
        )
    except Exception as e:
        return False, str(e)


def build_and_push_docker_image(
    lambda_folder_path: str, ecr_uri: str, tag: str = "latest"
) -> bool:
    dockerfile_path = os.path.join(lambda_folder_path, "Dockerfile")
    full_image_tag = f"{ecr_uri}:{tag}"
    build_context = lambda_folder_path

    logging.info("--- Starting Docker Build and ECR Push Process ---")
    logging.info(f"Dockerfile Path:    {dockerfile_path}")
    logging.info(f"Build Context:      {build_context}")
    logging.info(f"ECR Repository URI: {ecr_uri}")
    logging.info(f"Final Tag:          {full_image_tag}")
    logging.info("-" * 40)

    logging.info(f"Building Docker image: {full_image_tag}...")
    build_command = [
        "docker",
        "build",
        "-t",
        full_image_tag,
        "-f",
        dockerfile_path,
        build_context,
    ]

    success, message = run_command(build_command, check_error=False, stream_output=True)
    if not success:
        logging.error("Docker build failed.")
        logging.error(message)
        return False
    logging.info("Docker image built successfully.")
    logging.info("-" * 40)

    logging.info("Pushing image to ECR...")
    push_command = ["docker", "push", full_image_tag]

    success, message = run_command(push_command, check_error=False, stream_output=True)
    if not success:
        logging.error("Docker push failed. Ensure you are logged into ECR.")
        logging.error(message)
        return False

    logging.info("Docker image pushed successfully.")
    logging.info("-" * 40)
    logging.info(f"Process Complete. Image available as: {full_image_tag}")

    return True


def main() -> None:
    lambda_folder_paths = get_lambda_folder_paths()
    remote_ecr_repos = get_ecr_repositories()

    for lambda_folder_path in lambda_folder_paths:
        logging.info(f"Checking lambda package at: {lambda_folder_path}")

        config_filepath = os.path.join(lambda_folder_path, "config.json")
        lambda_config = read_lambda_config_file(config_filepath)

        current_dockerfile_hash, current_source_code_hash, current_package_file_hash = (
            lambda_config.get("dockerfile_sha256_hash"),
            lambda_config.get("source_code_sha256_hash"),
            lambda_config.get("package_files_sha256_hash"),
        )
        current_hashes = (
            current_dockerfile_hash,
            current_source_code_hash,
            current_package_file_hash,
        )

        new_dockerfile_hash, new_source_code_hash, new_package_files_hash = (
            compute_sha256_of_lambda_src(lambda_config, lambda_folder_path)
        )
        new_hashes = (new_dockerfile_hash, new_source_code_hash, new_package_files_hash)

        logging.info(f"Writing updated hashes to config file at {config_filepath}")
        write_hashes_to_file(
            config_filepath,
            lambda_config,
            new_dockerfile_hash,
            new_source_code_hash,
            new_package_files_hash,
        )

        if any(
            current_hash != new_hash
            for current_hash, new_hash in zip(current_hashes, new_hashes)
        ):
            logging.info(
                f"Changes detected in {lambda_folder_path}. Building and pushing image."
            )
            matching_ecr_repo = get_matching_ecr_repo(
                lambda_folder_path, remote_ecr_repos
            )
            if matching_ecr_repo:
                repo_arn = matching_ecr_repo.get("repositoryArn", "")
                repo_uri = matching_ecr_repo.get("repositoryUri", "")

                logging.info(f"Found matching ECR repository: {repo_arn}")
                build_finished = build_and_push_docker_image(
                    lambda_folder_path, repo_uri, "latest"
                )
                if build_finished:
                    logger.info(
                        f"Successfully built and pushed Docker image to ECR registry for {lambda_folder_path}"
                    )
                else:
                    logging.error(
                        f"Failed to build and push Docker image for {lambda_folder_path}"
                    )

                    logger.info(
                        f"Rolling back hashes to previous values at config file at {config_filepath}"
                    )
                    write_hashes_to_file(
                        config_filepath,
                        lambda_config,
                        current_dockerfile_hash or "",
                        current_source_code_hash or "",
                        current_package_file_hash or "",
                    )
        else:
            logger.info(f"No changes detected in {lambda_folder_path}. Skipping build.")

    sys.exit(0)


if __name__ == "__main__":
    main()
