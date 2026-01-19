FROM ubuntu:22.04

# Install base dependencies and Python
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    tar \
    libicu70 \
    liblttng-ust1 \
    libssl3 \
    zlib1g \
    ca-certificates \
    sudo \
    wget \
    unzip \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    apt-transport-https \
    gnupg \
    lsb-release \
    openssh-client \
    rsync \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI only (will use host Docker daemon)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Create runner user with sudo access
RUN useradd -m -s /bin/bash runner && \
    usermod -aG sudo runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Download and install GitHub Actions runner
WORKDIR /home/runner
RUN RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//') && \
    curl -o actions-runner-linux-x64.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf actions-runner-linux-x64.tar.gz && \
    rm actions-runner-linux-x64.tar.gz && \
    chown -R runner:runner /home/runner

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown runner:runner /entrypoint.sh

# Switch to runner user
USER runner

ENTRYPOINT ["/entrypoint.sh"]