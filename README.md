# Self-Hosted Deploy Scripts

Cross-platform deployment scripts for pushing web applications to your own server (VPS, Raspberry Pi, etc.) with a single command.

## Quick Start

```bash
# 1. Copy this folder into your project root
cp -r deploy/ /path/to/your-project/

# 2. Create your config file
cd your-project/deploy
cp config.example.json config.json
# Edit config.json with your server details

# 3. Deploy (from anywhere in your project)
./deploy/deploy.sh          # Linux/macOS
./deploy/deploy-powershell.ps1  # Windows
```

## What It Does

1. **Builds** your project (`npm run build`)
2. **Compresses** the build directory into a single archive
3. **Transfers** the archive to your server via SCP
4. **Deploys** by extracting to your web root with correct permissions

## Requirements

**Local Machine:**
- Node.js and npm
- SSH client (built into macOS/Linux, enable OpenSSH on Windows)
- tar (built into macOS/Linux/Windows 10+)

**Remote Server:**
- Linux with SSH access
- Web server (Nginx recommended)
- tar

## Project Types

Works with any project that builds to static files:
- **SPAs**: React, Vue, Angular, Svelte
- **SSGs**: Next.js (static export), Gatsby, Hugo, Jekyll, Eleventy
- **Vanilla**: HTML/CSS/JS with a build step

## Configuration

Create `deploy/config.json` from the example:

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

## File Structure

```
your-project/
├── deploy/
│   ├── deploy.sh            # Bash script (Linux/macOS)
│   ├── deploy-powershell.ps1 # PowerShell script (Windows)
│   ├── config.json          # Your server config (git-ignored)
│   ├── config.example.json  # Template config
│   ├── README.md
│   ├── INSTRUCTIONS.md      # Full setup guide
│   └── LICENSE
├── src/
├── package.json
└── ...
```

## Full Setup Guide

For complete server setup instructions including Nginx configuration and Cloudflare DNS/Tunnel setup, see **[INSTRUCTIONS.md](./INSTRUCTIONS.md)**.

## License

MIT - see [LICENSE](./LICENSE)
