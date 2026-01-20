#!/bin/bash
set -e

# Note: iptables rules disabled when using host networking mode
# Host networking provides direct network access
# For network restrictions with host mode, configure firewall on the host OS

# Fix docker socket permissions if mounted (running as root initially)
if [ -S /var/run/docker.sock ]; then
    DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
    echo "Docker socket found with GID: ${DOCKER_SOCK_GID}"
    
    # Add docker group with matching GID if needed
    if ! getent group ${DOCKER_SOCK_GID} > /dev/null 2>&1; then
        groupadd -g ${DOCKER_SOCK_GID} docker-host
        usermod -aG docker-host runner
    else
        DOCKER_GROUP=$(getent group ${DOCKER_SOCK_GID} | cut -d: -f1)
        usermod -aG ${DOCKER_GROUP} runner
    fi
fi

# Pre-create and fix ownership of work directories
mkdir -p "${RUNNER_WORKDIR}"
mkdir -p "${RUNNER_WORKDIR}/_tool"
mkdir -p "${RUNNER_WORKDIR}/_temp"
mkdir -p "${RUNNER_WORKDIR}/_temp/_runner_file_commands"
mkdir -p "${RUNNER_WORKDIR}/_actions"
chown -R runner:runner "${RUNNER_WORKDIR}"
chmod -R 755 "${RUNNER_WORKDIR}"

# Validate required environment variables
if [ -z "$GITHUB_OWNER" ]; then
    echo "Error: GITHUB_OWNER environment variable is not set"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set"
    exit 1
fi

# Generate unique runner name using hostname suffix
RUNNER_NAME="${RUNNER_NAME:-runner}-$(hostname | cut -c1-12)"
export RUNNER_NAME
echo "Runner name: ${RUNNER_NAME}"

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

# Switch to runner user for configuration and execution
cd /home/runner
exec su runner -c '
set -e

# Cleanup function
cleanup() {
    echo "Removing runner..."
    if [ -f ".runner" ]; then
        ./config.sh remove --token "'"${RUNNER_TOKEN}"'"
    fi
}

trap "cleanup; exit 130" INT
trap "cleanup; exit 143" TERM

# Configure the runner only if not already configured
if [ -f ".runner" ]; then
    echo "Runner configuration found, removing old registration..."
    ./config.sh remove --token "'"${RUNNER_TOKEN}"'" 2>/dev/null || true
    rm -f .runner .credentials .credentials_rsaparams 2>/dev/null || true
fi

echo "Configuring GitHub Actions runner..."
./config.sh \
    --url "'"${REGISTRATION_URL}"'" \
    --token "'"${RUNNER_TOKEN}"'" \
    --name "'"${RUNNER_NAME}"'" \
    --work "'"${RUNNER_WORKDIR}"'" \
    --labels "'"${RUNNER_LABELS}"'" \
    --runnergroup "'"${RUNNER_GROUP}"'" \
    --unattended \
    --replace

# Start the runner
echo "Starting GitHub Actions runner..."
./run.sh & wait $!
'
