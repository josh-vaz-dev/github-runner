# GitHub Actions Self-Hosted Runner

A Dockerized GitHub Actions self-hosted runner that can be deployed on Windows (Docker Desktop/WSL2), Linux, or Proxmox Virtual Environment. Run GitHub Actions workflows on your own infrastructure with ease.

## Features

- 🐳 Fully containerized GitHub Actions runner
- 🔄 Automatic runner registration and de-registration
- 🏷️ Customizable runner labels
- 📦 Docker-in-Docker support for container-based workflows
- ♻️ Auto-restart on failure
- 🔧 Easy configuration via environment variables
- 🏢 Supports both organization and repository runners
- 💻 Works on Windows, Linux, macOS, and Proxmox

## Prerequisites

### General Requirements
- Git
- Docker and Docker Compose
- GitHub account with appropriate permissions
- Minimum 2GB RAM and 20GB disk space

### Platform-Specific
- **Windows**: Docker Desktop for Windows OR WSL2 with Docker
- **Linux/macOS**: Docker and Docker Compose installed
- **Proxmox**: VM or LXC container with Docker installed

## Quick Start

### 1. Create a GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Self-Hosted Runner")
4. Select scopes:
   - For **repository runners**: `repo` (Full control of private repositories)
   - For **organization runners**: `admin:org` (Full control of orgs and teams)
5. Click "Generate token" and copy it immediately (you won't see it again)

### 2. Choose Your Deployment Platform

## 🪟 Windows - Docker Desktop (Easiest!)

### Prerequisites
- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop) installed and running
- Git for Windows

### Setup Steps

1. **Open PowerShell or Terminal**

2. **Clone the repository**
   ```powershell
   git clone https://github.com/josh-vaz-dev/github-runner.git
   cd github-runner
   ```

3. **Configure environment variables**
   ```powershell
   copy .env.example .env
   notepad .env
   ```
   
   Edit the `.env` file:
   ```bash
   # For repository runner:
   GITHUB_OWNER=your-username
   GITHUB_REPOSITORY=your-repo
   GITHUB_TOKEN=ghp_your_token_here
   RUNNER_NAME=windows-docker-runner
   RUNNER_LABELS=self-hosted,windows-docker,local
   
   # For organization runner (leave GITHUB_REPOSITORY empty):
   GITHUB_OWNER=your-org-name
   GITHUB_REPOSITORY=
   GITHUB_TOKEN=ghp_your_token_here
   RUNNER_NAME=windows-docker-runner
   ```

4. **Start the runner**
   ```powershell
   docker-compose up -d
   ```

5. **Verify it's running**
   ```powershell
   docker-compose logs -f
   # Look for "Listening for Jobs" message
   ```

6. **Check on GitHub**
   - Go to your repository/organization Settings → Actions → Runners
   - Your runner should appear as "Idle" and ready to accept jobs

### Stopping the Runner
```powershell
docker-compose down
```

## 🐧 WSL2 on Windows (Recommended for Development)

WSL2 provides a native Linux environment on Windows with excellent Docker integration.

### Prerequisites
- WSL2 enabled on Windows
- Ubuntu (or another Linux distro) installed in WSL2
- Docker Desktop with WSL2 backend enabled

### Setup Steps

1. **Open WSL2 terminal** (Ubuntu)

2. **Ensure Docker is accessible**
   ```bash
   docker --version
   # Should show Docker version without errors
   ```

3. **Clone the repository**
   ```bash
   git clone https://github.com/josh-vaz-dev/github-runner.git
   cd github-runner
   ```

4. **Configure environment variables**
   ```bash
   cp .env.example .env
   nano .env  # or use 'vim' or 'code .env'
   ```
   
   Edit the `.env` file:
   ```bash
   GITHUB_OWNER=your-username
   GITHUB_REPOSITORY=your-repo
   GITHUB_TOKEN=ghp_your_token_here
   RUNNER_NAME=wsl2-runner
   RUNNER_LABELS=self-hosted,wsl2,linux,local
   ```

5. **Start the runner**
   ```bash
   docker-compose up -d
   ```

6. **Verify the runner**
   ```bash
   docker-compose logs -f
   ```

### Auto-Start on Windows Boot (Optional)

Create a Windows Task or add to startup:
```powershell
# In PowerShell (as Administrator)
wsl -d Ubuntu -e bash -c "cd ~/github-runner && docker-compose up -d"
```

## 🖥️ Proxmox Virtual Environment

Perfect for homelab setups and production deployments.

### Prerequisites on Proxmox
- Proxmox VE 7.0 or higher
- A Linux VM or LXC container (Ubuntu 22.04 LTS recommended)
- Internet connectivity

### Option A: Using Ubuntu VM

1. **Create Ubuntu VM in Proxmox**
   ```bash
   # In Proxmox web UI:
   # - Create VM → Select Ubuntu 22.04 ISO
   # - Allocate: 2 CPU cores, 4GB RAM, 32GB disk
   # - Start VM and complete Ubuntu installation
   ```

2. **SSH into your VM**
   ```bash
   ssh user@your-vm-ip
   ```

3. **Install Docker and Docker Compose**
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Add your user to docker group
   sudo usermod -aG docker $USER
   
   # Install Docker Compose
   sudo apt install docker-compose -y
   
   # Logout and login again for group changes to take effect
   exit
   ```

4. **Clone this repository**
   ```bash
   ssh user@your-vm-ip
   git clone https://github.com/YOUR_USERNAME/github-runner.git
   cd github-runner
   ```

5. **Configure environment variables**
   ```bash
   cp .env.example .env
   nano .env
   ```
   
   Edit the `.env` file:
   ```bash
   # For repository runner:
   GITHUB_OWNER=your-username
   GITHUB_REPOSITORY=your-repo
   GITHUB_TOKEN=ghp_your_token_here
   RUNNER_NAME=proxmox-runner-1
   RUNNER_LABELS=self-hosted,proxmox,linux
   
   # For organization runner (leave GITHUB_REPOSITORY empty):
   GITHUB_OWNER=your-org-name
   GITHUB_REPOSITORY=
   GITHUB_TOKEN=ghp_your_token_here
   RUNNER_NAME=proxmox-org-runner-1
   RUNNER_LABELS=self-hosted,proxmox,linux
   ```

6. **Start the runner**
   ```bash
   docker-compose up -d
   ```

7. **Verify the runner is running**
   ```bash
   # Check logs
   docker-compose logs -f
   
   # You should see "Listening for Jobs" message
   ```

8. **Verify on GitHub**
   - Go to your repository Settings → Actions → Runners (for repo runners)
   - Or go to your organization Settings → Actions → Runners (for org runners)
   - You should see your runner listed as "Idle"

#### Option B: Using LXC Container

1. **Create LXC Container in Proxmox**
   ```bash
   # In Proxmox web UI:
   # Create CT → Ubuntu 22.04 template
   # Enable: Nesting, Keyctl
   # Allocate: 2 cores, 4GB RAM, 32GB disk
   ```

2. **Enable Docker in LXC**
   
   Edit the LXC config on the Proxmox host:
   ```bash
   # On Proxmox host, edit /etc/pve/lxc/{CTID}.conf
   nano /etc/pve/lxc/100.conf  # Replace 100 with your CT ID
   
   # Add these lines:
   lxc.apparmor.profile: unconfined
   lxc.cgroup2.devices.allow: a
   lxc.cap.drop:
   lxc.mount.auto: proc:rw sys:rw
   ```

3. **Start LXC and install Docker**
   ```bash
   # Start the container from Proxmox UI
   # Enter the container
   pct enter 100  # Replace with your CT ID
   
   # Install Docker
   apt update && apt upgrade -y
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   apt install docker-compose -y
   ```

4. **Continue with steps 4-8 from Option A**

## Configuration Options

### Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `GITHUB_OWNER` | Yes | GitHub username or organization name | - |
| `GITHUB_REPOSITORY` | No* | Repository name (leave empty for org runners) | - |
| `GITHUB_TOKEN` | Yes | GitHub Personal Access Token | - |
| `RUNNER_NAME` | No | Name for this runner instance | `proxmox-runner` |
| `RUNNER_WORKDIR` | No | Working directory for jobs | `/home/runner/_work` |
| `RUNNER_LABELS` | No | Comma-separated labels | `self-hosted,proxmox,docker` |
| `RUNNER_GROUP` | No | Runner group name | `Default` |

*Leave `GITHUB_REPOSITORY` empty for organization-level runners

### Custom Labels

You can customize runner labels to target specific runners in your workflows:

```yaml
# In .env file
RUNNER_LABELS=self-hosted,proxmox,docker,gpu,high-memory
```

Then in your workflow:
```yaml
jobs:
  build:
    runs-on: [self-hosted, proxmox, gpu]
```

## Managing the Runner

### View logs
```bash
docker-compose logs -f
```

### Stop the runner
```bash
docker-compose down
```

### Restart the runner
```bash
docker-compose restart
```

### Update the runner
```bash
docker-compose down
docker-compose pull
docker-compose up -d --build
```

### Remove the runner completely
```bash
docker-compose down -v
```

## Running Multiple Runners

To run multiple runners on the same host:

1. Create separate directories for each runner
2. Copy all files to each directory
3. Edit `.env` in each directory with unique `RUNNER_NAME`
4. Run `docker-compose up -d` in each directory

Or use a single compose file with multiple services:

```yaml
services:
  github-runner-1:
    # ... config ...
    environment:
      - RUNNER_NAME=proxmox-runner-1
  
  github-runner-2:
    # ... config ...
    environment:
      - RUNNER_NAME=proxmox-runner-2
```

## Example Workflow

Create `.github/workflows/test.yml` in your repository:

```yaml
name: Test Self-Hosted Runner

on: [push]

jobs:
  test:
    runs-on: [self-hosted, proxmox]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Test runner
        run: |
          echo "Running on self-hosted runner!"
          uname -a
          docker --version
```

## Multi-Host Deployments

The runner includes SSH tools for deploying to multiple locations (local machine, Raspberry Pi, Proxmox, etc.).

### Setup Deployment Targets

**Option 1: Using 1Password (Recommended)**

The runner includes 1Password CLI for secure secret management.

1. **Create a 1Password Service Account**
   - Go to 1Password → Developer Tools → Service Accounts
   - Create service account with read access to your deployment vault
   - Copy the `OP_SERVICE_ACCOUNT_TOKEN`

2. **Add service account token to GitHub**
   - Repository/Organization Settings → Secrets → New secret
   - Name: `OP_SERVICE_ACCOUNT_TOKEN`
   - Value: Your service account token

3. **Store secrets in 1Password**
   - Create a vault: "GitHub Deployments"
   - Add SSH Key items: `pi5-ssh-key`, `proxmox-ssh-key`
   - Add config item: `deployment-config` with fields:
     - PI5_HOST
     - PI5_USER
     - PROXMOX_HOST
     - PROXMOX_USER

4. **Use in workflows:**
```yaml
- name: Load secrets from 1Password
  uses: 1password/load-secrets-action@v1
  with:
    export-env: true
  env:
    OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
    PI5_HOST: op://GitHub Deployments/deployment-config/PI5_HOST
    PI5_USER: op://GitHub Deployments/deployment-config/PI5_USER
    PI5_SSH_KEY: op://GitHub Deployments/pi5-ssh-key/private key
```

**Option 2: Using GitHub Secrets**

Add to your repository/organization Settings → Secrets and variables → Actions:
- `PI5_HOST` = `192.168.1.100`
- `PI5_USER` = `pi`
- `PI5_SSH_KEY` = (your private SSH key content)
- `PROXMOX_HOST` = `192.168.1.50`
- `PROXMOX_USER` = `root`
- `PROXMOX_SSH_KEY` = (your private SSH key content)

**Option 2: Using .env file (for non-sensitive configuration)**

Add to your `.env` file:
```bash
# Deployment targets
PI5_HOST=192.168.1.100
PI5_USER=pi
PROXMOX_HOST=192.168.1.50
PROXMOX_USER=root
```

Then mount an SSH key as a volume in `docker-compose.yml`:
```yaml
volumes:
  - runner-data:/home/runner/_work
  - /var/run/docker.sock:/var/run/docker.sock
  - ~/.ssh/deploy_key:/home/runner/.ssh/deploy_key:ro
```

### Example Deployment Workflow

```yaml
name: Deploy to Multiple Hosts
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: self-hosted
    
    steps:
      - uses: actions/checkout@v4
      
      # Build Docker image
      - name: Build Image
        run: docker build -t myapp:latest .
      
      # Deploy to local machine (Windows host)
      - name: Deploy Locally
        run: docker-compose -f docker-compose.prod.yml up -d
      
      # Deploy to Raspberry Pi 5
      - name: Deploy to Pi5
        env:
          PI_HOST: ${{ secrets.PI5_HOST }}
          PI_USER: ${{ secrets.PI5_USER }}
          PI_KEY: ${{ secrets.PI5_SSH_KEY }}
        run: |
          echo "$PI_KEY" > /tmp/pi_key
          chmod 600 /tmp/pi_key
          
          # Copy compose file
          scp -i /tmp/pi_key -o StrictHostKeyChecking=no \
            docker-compose.yml $PI_USER@$PI_HOST:/home/$PI_USER/app/
          
          # Deploy on Pi
          ssh -i /tmp/pi_key -o StrictHostKeyChecking=no $PI_USER@$PI_HOST \
            "cd /home/$PI_USER/app && docker-compose pull && docker-compose up -d"
          
          rm /tmp/pi_key
      
      # Deploy to Proxmox VM
      - name: Deploy to Proxmox
        env:
          PROXMOX_HOST: ${{ secrets.PROXMOX_HOST }}
          PROXMOX_USER: ${{ secrets.PROXMOX_USER }}
          PROXMOX_KEY: ${{ secrets.PROXMOX_SSH_KEY }}
        run: |
          echo "$PROXMOX_KEY" > /tmp/proxmox_key
          chmod 600 /tmp/proxmox_key
          
          ssh -i /tmp/proxmox_key -o StrictHostKeyChecking=no \
            $PROXMOX_USER@$PROXMOX_HOST \
            "docker pull myapp:latest && cd /opt/myapp && docker-compose up -d"
          
          rm /tmp/proxmox_key
```

### Using Docker Contexts (Advanced)

For cleaner deployment commands, configure Docker contexts:

```yaml
- name: Setup Docker Contexts
  run: |
    docker context create pi5 --docker "host=ssh://${{ secrets.PI5_USER }}@${{ secrets.PI5_HOST }}"
    docker context create proxmox --docker "host=ssh://${{ secrets.PROXMOX_USER }}@${{ secrets.PROXMOX_HOST }}"

- name: Deploy to Pi5
  run: docker --context pi5 compose up -d

- name: Deploy to Proxmox
  run: docker --context proxmox compose up -d
```

### SSH Key Setup

Generate deployment SSH keys on each target:

```bash
# On your Pi5/Proxmox
ssh-keygen -t ed25519 -C "github-runner-deploy" -f ~/.ssh/github_deploy
cat ~/.ssh/github_deploy.pub >> ~/.ssh/authorized_keys

# Copy the private key content
cat ~/.ssh/github_deploy
# Add this to GitHub Secrets as PI5_SSH_KEY
```

## Troubleshooting

### Runner not appearing in GitHub

1. Check logs: `docker-compose logs -f`
2. Verify GitHub token has correct permissions
3. Ensure token hasn't expired
4. Check network connectivity from the container

### Windows/Docker Desktop Issues

**Container won't start:**
- Ensure Docker Desktop is running
- Check that WSL2 backend is enabled (Settings → General → Use WSL2)
- Verify virtualization is enabled in BIOS

**Performance issues:**
- Allocate more resources to Docker Desktop (Settings → Resources)
- Recommended: 4GB RAM minimum, 2 CPU cores

**File sharing errors:**
- Enable file sharing for the drive where your code is located (Settings → Resources → File Sharing)

### WSL2 Issues

**Docker command not found:**
```bash
# Ensure Docker Desktop integration is enabled for your WSL2 distro
# Docker Desktop → Settings → Resources → WSL Integration
```

**Slow performance:**
- Store files in WSL2 filesystem (`~/`) not Windows filesystem (`/mnt/c/`)
- Clone the repo directly in WSL2: `cd ~; git clone ...`

### Linux/Proxmox Issues

**Permission denied errors:**
```bash
# Ensure user is in docker group
sudo usermod -aG docker $USER
# Logout and login again
```

**LXC container issues:**
1. Verify nesting is enabled in container config
2. Check AppArmor profile is set to unconfined
3. Restart container after config changes

**Docker socket errors:**
```bash
# Check socket permissions
ls -la /var/run/docker.sock

# Fix if needed (temporary)
sudo chmod 666 /var/run/docker.sock
```

## Security Considerations

- 🔐 Never commit `.env` file with real tokens to git
- 🔑 Use GitHub Personal Access Tokens with minimal required scopes
- 🛡️ Regularly rotate access tokens
- 🔒 Consider running runners in isolated VMs/containers
- 👥 For organization runners, restrict to specific repositories
- 🔍 Monitor runner activity regularly
- 🚫 Be cautious with public repositories - consider using ephemeral runners
- 💻 **Local development**: Runners on your PC can access your local files and network
- 🏠 **Homelab/Proxmox**: Consider network segmentation for runners

## Platform-Specific Best Practices

### Windows/WSL2
- **Resource Allocation**: Configure Docker Desktop resources appropriately
- **Storage**: Keep runner workspace on fast SSD
- **Auto-start**: Create startup task if you want runner always available
- **Updates**: Keep Docker Desktop and WSL2 updated
- **Performance**: Use WSL2 filesystem for best performance

### Proxmox Production
1. **Resource Allocation**
   - Minimum: 2 CPU cores, 4GB RAM, 32GB disk
   - Recommended: 4 CPU cores, 8GB RAM, 50GB disk
   - For heavy workloads: Scale accordingly

2. **Backups**
   - Regular VM/LXC snapshots before updates
   - Backup `.env` file securely

3. **Monitoring**
   - Set up Proxmox monitoring for CPU/RAM usage
   - Monitor disk space usage
   - Set up alerts for container/VM failures

4. **Networking**
   - Ensure stable network connection
   - Consider static IP assignment
   - Configure firewall rules if needed

## Updating Runner Version

To update to a newer GitHub Actions runner version:

1. Edit `Dockerfile`
2. Update `RUNNER_VERSION` ARG to desired version
3. Rebuild:
   ```bash
   docker-compose down
   docker-compose up -d --build
   ```

Check available versions: https://github.com/actions/runner/releases

## License

MIT License - feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Docker Documentation](https://docs.docker.com/)
