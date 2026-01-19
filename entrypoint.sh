#!/bin/bash
set -e

# Validate required environment variables
if [ -z "$GITHUB_OWNER" ]; then
    echo "Error: GITHUB_OWNER environment variable is not set"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set"
    exit 1
fi

# Determine registration URL and scope
if [ -z "$GITHUB_REPOSITORY" ]; then
    # Organization runner
    REGISTRATION_URL="https://github.com/${GITHUB_OWNER}"
    echo "Configuring organization runner for: ${GITHUB_OWNER}"
else
    # Repository runner
    REGISTRATION_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}"
    echo "Configuring repository runner for: ${GITHUB_OWNER}/${GITHUB_REPOSITORY}"
fi

# Get registration token
echo "Obtaining registration token..."
if [ -z "$GITHUB_REPOSITORY" ]; then
    # Organization token endpoint
    TOKEN_URL="https://api.github.com/orgs/${GITHUB_OWNER}/actions/runners/registration-token"
else
    # Repository token endpoint
    TOKEN_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
fi

RUNNER_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "${TOKEN_URL}" | jq -r .token)

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
    echo "Error: Failed to obtain registration token. Check your GITHUB_TOKEN permissions."
    echo "The token needs 'repo' (for repository runners) or 'admin:org' (for organization runners) scope."
    exit 1
fi

# Configure the runner
echo "Configuring GitHub Actions runner..."
./config.sh \
    --url "${REGISTRATION_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --runnergroup "${RUNNER_GROUP}" \
    --unattended \
    --replace

# Cleanup function
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${RUNNER_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start the runner
echo "Starting GitHub Actions runner..."
./run.sh & wait $!
