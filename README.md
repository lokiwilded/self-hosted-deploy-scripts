# Self-Hosted Deploy Scripts

Cross-platform deployment scripts for pushing web applications to your own server (VPS, Raspberry Pi, home server) with a single command.

## Why Self-Host?

Skip the monthly hosting fees. Run your sites on hardware you own - a $50 Raspberry Pi can serve multiple websites. Combined with **Cloudflare Zero Trust Tunnels**, you get enterprise-grade security without opening ports on your router or exposing your home IP address.

### How Cloudflare Tunnels Work

Instead of traditional port forwarding (which exposes your network), Cloudflare Tunnels create an outbound-only connection from your server to Cloudflare's edge network:

```
[Your Domain] → [Cloudflare Edge] ← secure tunnel ← [Your Pi/Server]
                                                          ↑
                                              (no open ports needed)
```

- **No port forwarding** - Your router stays locked down
- **DDoS protection** - Cloudflare absorbs attacks before they reach you
- **Free SSL** - Automatic HTTPS certificates
- **Hidden origin IP** - Your home IP stays private

The [full setup guide](./INSTRUCTIONS.md) walks through configuring this step-by-step.

---

## Quick Start

```bash
# 1. Copy this folder into your project root
cp -r self-hosted-deploy-scripts/ /path/to/your-project/deploy/

# 2. Create your config file
cd your-project/deploy
cp config.example.json config.json
# Edit config.json with your server details

# 3. Deploy (from anywhere in your project)
./deploy/deploy.sh          # Linux/macOS
./deploy/deploy-powershell.ps1  # Windows
```

## What It Does

1. **Builds** your project (`npm run build` or custom command)
2. **Compresses** the build directory into a single archive
3. **Transfers** the archive to your server via SCP
4. **Deploys** by extracting to your web root with correct permissions

## Full Setup Guide

**[INSTRUCTIONS.md](./INSTRUCTIONS.md)** covers everything:
- Server preparation (Nginx install, directory setup)
- SSH key configuration for passwordless deploys
- Domain setup with Cloudflare DNS
- Cloudflare Zero Trust Tunnel configuration
- Running the tunnel as a system service

---

## Requirements

**Local Machine:**
- Node.js and npm (or yarn)
- SSH client (built into macOS/Linux, enable OpenSSH on Windows)
- tar (built into macOS/Linux/Windows 10+)

**Remote Server:**
- Linux with SSH access
- Web server (Nginx recommended)
- tar

## Supported Project Types

Works with any project that builds to static files:
- **SPAs**: React, Vue, Angular, Svelte
- **SSGs**: Next.js (static export), Gatsby, Hugo, Jekyll, Eleventy
- **Vanilla**: HTML/CSS/JS with a build step

## Configuration

Create `config.json` from the example:

```json
{
  "piUser": "your_username",
  "piIpAddress": "192.168.1.100",
  "tempDirOnPi": "/home/your_username/deploy_temp",
  "finalDirOnPi": "/var/www/html/your-site.com",
  "buildCommand": "npm run build",
  "buildDir": "build"
}
```

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `piUser` | Yes | - | SSH username on remote server |
| `piIpAddress` | Yes | - | Server IP or hostname |
| `tempDirOnPi` | Yes | - | Temp directory for uploads |
| `finalDirOnPi` | Yes | - | Web root directory |
| `buildCommand` | No | `npm run build` | Build command (use `yarn build` etc.) |
| `buildDir` | No | `build` | Output folder (`dist` for Vite/Vue) |

**Add to your `.gitignore`:**
```
deploy/config.json
```

## License

MIT - see [LICENSE](./LICENSE)
