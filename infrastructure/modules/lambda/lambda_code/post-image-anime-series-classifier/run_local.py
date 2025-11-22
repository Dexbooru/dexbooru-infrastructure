import json
import logging
import os

import requests

logger = logging.getLogger(__name__)


def main():
    port = os.environ.get("PORT", "9000")
    mock_payload_path = os.environ.get("MOCK_PAYLOAD_PATH", "mock_payload.json")

    if len(mock_payload_path) == 0:
        raise ValueError("MOCK_PAYLOAD_PATH environment variable is not set")

    if not port.isnumeric():
        raise ValueError("PORT environment variable is not a number")

    lambda_url = f"http://localhost:{port}/2015-03-31/functions/function/invocations"

    try:
        with open(mock_payload_path, mode="r") as file:
            logger.info("Reading mock payload from file at: %s", mock_payload_path)
            mock_payload = json.loads(file.read())

            logger.info("Invoking local lambda function at url: %s", lambda_url)
            response = requests.post(lambda_url, json=mock_payload)

            if not response.ok:
                logger.error(
                    f"Request failed with status code {response.status_code}: {response.text}"
                )

            resp_body = response.json()
            logger.info("Lambda response: %s", resp_body)

    except FileNotFoundError as e:
        logger.error(f"File not found: {e}")
    except requests.RequestException as e:
        logger.error(f"Request failed: {e}")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")


if __name__ == "__main__":
    main()
