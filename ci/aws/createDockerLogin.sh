#!/bin/bash

# Set Docker login user for AWS ECR
DOCKER_LOGIN_USER="AWS"

# Increase metadata service timeout and number of attempts for IAM role
# Increase number of seconds for timeout to 20. Default value is 1 second.
export AWS_METADATA_SERVICE_TIMEOUT=20
# Increase number of attempts before giving up to 3. Default value is 1 attempt.
export AWS_METADATA_SERVICE_NUM_ATTEMPTS=3

# Use 'ecr get-login-password' instead of deprecated 'ecr get-login'
# Set AWS region with CLI option instead of 'aws configure set region'
# --debug prints to stderr
DOCKER_LOGIN_PASSWORD=$($1 ecr get-login-password --region eu-central-1 --debug)
if [ -z ${DOCKER_LOGIN_PASSWORD} ]; then
    >&2 echo 'ERROR: ${DOCKER_LOGIN_PASSWORD} is empty from "aws ecr get-login-password" call. Docker push to AWS ECR will not work. Exit 1.'
    exit 1
fi

# Get base64 encoded <username>:<password> for config.json file
BASE64_LOGIN=$(echo "${DOCKER_LOGIN_USER}:${DOCKER_LOGIN_PASSWORD}" | base64 -w0 -)

# Echo to stdout, Bazel will write this to config.json for Bazel Docker push rules
echo "{\"auths\": {\"$2.dkr.ecr.eu-central-1.amazonaws.com\": {\"auth\": \"${BASE64_LOGIN}\"}},\"HttpHeaders\": {\"User-Agent\": \"Docker-Client/19.03.1 (linux)\"}}"
