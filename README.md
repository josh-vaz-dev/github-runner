# GitHub Actions Self-Hosted Runner for Proxmox

A Dockerized GitHub Actions self-hosted runner designed for deployment on Proxmox Virtual Environment (PVE). This setup allows you to run GitHub Actions workflows on your own infrastructure.

## Features

- 🐳 Fully containerized GitHub Actions runner
- 🔄 Automatic runner registration and de-registration
- 🏷️ Customizable runner labels
- 📦 Docker-in-Docker support for container-based workflows
- ♻️ Auto-restart on failure
- 🔧 Easy configuration via environment variables
- 🏢 Supports both organization and repository runners

## Prerequisites

### On Your Local Machine
- Git
- GitHub account with appropriate permissions

### On Proxmox Server
- Proxmox VE 7.0 or higher
- A Linux VM or LXC container (Ubuntu 22.04 LTS recommended)
- Docker and Docker Compose installed
- Minimum 2GB RAM and 20GB disk space
- Internet connectivity

## Quick Start

### 1. Create a GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Proxmox Runner")
4. Select scopes:
   - For **repository runners**: `repo` (Full control of private repositories)
   - For **organization runners**: `admin:org` (Full control of orgs and teams)
5. Click "Generate token" and copy it immediately (you won't see it again)

### 2. Set Up on Proxmox

#### Option A: Using Ubuntu VM

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
   
   # For organization runner (leave GITHUB_REPOSITORY empty):
   GITHUB_OWNER=your-org-name
   GITHUB_REPOSITORY=
   GITHUB_TOKEN=ghp_your_token_here
   RUNNER_NAME=proxmox-org-runner-1
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

## Troubleshooting

### Runner not appearing in GitHub

1. Check logs: `docker-compose logs -f`
2. Verify GitHub token has correct permissions
3. Ensure token hasn't expired
4. Check network connectivity from the container

### Permission denied errors

```bash
# Ensure user is in docker group
sudo usermod -aG docker $USER
# Logout and login again
```

### LXC container issues

1. Verify nesting is enabled in container config
2. Check AppArmor profile is set to unconfined
3. Restart container after config changes

### Docker socket errors

```bash
# Check socket permissions
ls -la /var/run/docker.sock

# Fix if needed
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

## Proxmox Best Practices

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
