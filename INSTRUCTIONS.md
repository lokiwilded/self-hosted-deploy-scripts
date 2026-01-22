# Universal Web App Deployment Guide

A complete walkthrough for deploying web applications from your local machine to a self-hosted server. Covers server setup, DNS configuration, and Cloudflare integration.

---

## Part 1: Local Machine Setup

1.  **Copy to Your Project:** Take this entire `deploy` folder and place it in the root directory of your own project.

2.  **Prerequisites:** Ensure your local machine is ready.
    *   **Node.js & npm/yarn:** Required to build your project.
    *   **SSH Client:**
        *   **Windows:** The OpenSSH Client is a standard feature. To enable it, go to `Settings > System > Optional features`, find "OpenSSH Client" in the list, and click "Install".
        *   **macOS & Linux:** The SSH client is pre-installed.

3.  **Configuration File:**
    *   Inside the `deploy` folder, rename `config.example.json` to `config.json`.
    *   **IMPORTANT:** Add a line with `deploy/config.json` to your project's root `.gitignore` file to keep your server credentials private.

---

## Part 2: Server-Side Setup (The Remote Host)

These steps prepare your remote server (like a Raspberry Pi, a VPS, or any Linux machine) to receive and host your web application.

1.  **Connect to Your Server:**
    Log in to your server using the user account you intend to deploy with.
    ```bash
    ssh your_user@your_server_ip
    ```

2.  **Install Web Server (Nginx):**
    Nginx is a high-performance web server that will serve your project's files.
    ```bash
    sudo apt-get update
    sudo apt-get install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
    ```

3.  **Create Directories & Configure:**
    As you create the directories on your server, fill out the `deploy/config.json` file on your local machine.

    *   **On Server:** Create a temporary directory for file uploads and the final web root directory.
        ```bash
        # Example using /var/www/ for the web root and a temp folder in your home directory
        sudo mkdir -p /var/www/html/your_domain.com
        mkdir -p ~/my_build_temp
        ```
    *   **On Local Machine:** Edit `deploy/config.json` with the paths you just created and your server details.
        ```json
        {
          "piUser": "your_user",
          "piIpAddress": "your_server_ip",
          "tempDirOnPi": "/home/your_user/my_build_temp",
          "finalDirOnPi": "/var/www/html/your_domain.com",
          "buildCommand": "npm run build",
          "buildDir": "build"
        }
        ```
        *Note: `buildCommand` and `buildDir` are optional. Change `buildDir` to `dist` for Vite/Vue projects, or `buildCommand` to `yarn build` if using Yarn.*

4.  **Set Directory Permissions:**
    Give your user ownership of the web root directory to allow the script to write files to it.
    ```bash
    # Run on server, replacing 'your_user'
    sudo chown -R your_user:your_user /var/www/html/your_domain.com
    ```
    *Note: The deployment script runs several commands using `sudo`. You will be prompted for your password during deployment.*

5.  **Set Up SSH Keys (Optional but Recommended):**
    SSH keys allow passwordless login, making deployments smoother.

    On your **local machine**:
    ```bash
    # Generate a key pair (skip if you already have one)
    ssh-keygen -t ed25519 -C "your_email@example.com"

    # Copy your public key to the server
    ssh-copy-id your_user@your_server_ip
    ```
    After this, `ssh your_user@your_server_ip` should connect without asking for a password.

---

## Part 3: Domain and DNS Setup (Cloudflare)

Here are two methods to connect your domain to your server. The Cloudflare Tunnel method is recommended as it's more secure and avoids opening ports on your router.

### Method 1: Direct DNS `A` Record (Requires Port Forwarding)

This method points your domain directly to your home's public IP address.

1.  **Find Your Public IP:** On your server or any computer on the same network, open a web browser and search for "what is my ip". Note the IPv4 address.
2.  **Port Forward:** Log in to your router's admin panel and forward port `80` (for HTTP) and `443` (for HTTPS) to your server's local IP address. **For the deployment script to work, you must also forward port `22` (for SSH).**
3.  **Create Cloudflare DNS Record:**
    *   Log in to Cloudflare and go to the DNS section for your domain.
    *   Add an `A` record:
        *   **Type:** `A`
        *   **Name:** `@` (for the root domain) or `www`
        *   **IPv4 address:** Your public IP address from step 1.
        *   **Proxy status:** Can be on (orange cloud) or off.

### Method 2: Cloudflare Tunnel (Zero Trust - No Port Forwarding for Web)

This is a more secure method that creates a private tunnel from Cloudflare to your server without opening any web ports to the internet.

**Important:** This method is for securing your **website traffic**. For the deployment scripts (`scp`/`ssh`) to work, you must still have SSH accessible. This typically means you still need to **port forward port `22`** on your router to your server.

1.  **Install `cloudflared` on your Server:**
    Download and install the `cloudflared` daemon. Choose the correct architecture:
    ```bash
    # For Raspberry Pi / ARM64:
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb

    # For standard VPS / x86_64:
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

    # Install:
    sudo dpkg -i cloudflared.deb
    ```

2.  **Authenticate `cloudflared`:**
    Run this command on your server. It will give you a URL to log in to your Cloudflare account and authorize the tunnel.
    ```bash
    cloudflared tunnel login
    ```

3.  **Create a Tunnel and Point it to Nginx:**
    This command creates a tunnel and configures it to proxy requests to your local Nginx server. Replace `tunnel-name` and `your_domain.com` with your own details.
    ```bash
    # This single command creates the tunnel and the DNS record for you
    cloudflared tunnel create tunnel-name
    cloudflared tunnel route dns tunnel-name your_domain.com
    ```

4.  **Configure the Tunnel to Run as a Service:**
    *   Create a configuration file for your tunnel. The UUID is shown after you create the tunnel.
        ```bash
        sudo nano /etc/cloudflared/config.yml
        ```
    *   Add the following content, replacing the placeholders:
        ```yml
        tunnel: your_tunnel_uuid_here
        credentials-file: /home/your_user/.cloudflared/your_tunnel_uuid_here.json
        
        ingress:
          - hostname: your_domain.com
            service: http://localhost:80
          - service: http_status:404 # Catch-all
        ```
    *   Start the service:
        ```bash
        sudo cloudflared service install
        sudo systemctl start cloudflared
        ```
    Your site is now live through the secure tunnel!

---

## Part 4: The Deployment Workflow

With everything configured, deploying is a single command from your project's root directory.

#### For Linux or macOS (using Bash)
```bash
# Make the script executable (only need to do this once)
chmod +x ./deploy/deploy.sh

# Run it
./deploy/deploy.sh
```

#### For Windows (using PowerShell)
```powershell
./deploy/deploy-powershell.ps1
```
*If you see an error about execution policy, run this command first and then try again:*
`Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force`

