#!/bin/bash

cd ecr-scripts
source venv/bin/activate
python build_and_push_lambda_artifacts.py
deactivate
