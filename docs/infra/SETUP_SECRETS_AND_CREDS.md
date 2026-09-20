# 🔐 Setup Guide: Secrets, Credentials & 3rd-Party Configuration

This document lists all manual setup steps, third-party accounts, and GitHub repository secrets required for the Continuous Deployment (CD) pipelines across the Backend, Mobile, and Web applications.

---

## 1. Quick Summary Table

| Category | Secret Name | Required? | Where to Get / How to Generate |
| :--- | :--- | :---: | :--- |
| **API Base URL** | `API_BASE_URL` | **Yes (Mobile/Web)** | Cloudflare Tunnel URL (`https://...trycloudflare.com`) or production domain (`https://api.lokalaku.id`). |
| **Mobile Signing** | `ANDROID_KEYSTORE_BASE64` | For Mobile CD | Base64-encoded release `.jks` file: `base64 -i upload-keystore.jks \| pbcopy`. |
| **Mobile Signing** | `KEYSTORE_PASSWORD` | For Mobile CD | Keystore password chosen during key generation. |
| **Mobile Signing** | `KEY_ALIAS` | For Mobile CD | Alias name (e.g. `lokalaku-release`). |
| **Mobile Signing** | `KEY_PASSWORD` | For Mobile CD | Key alias password. |
| **Production VPS** | `VPS_HOST` | Only when deploying to VPS | Public IP or hostname of your Linux VPS. (If omitted, CI skips VPS deploy). |
| **Production VPS** | `VPS_USER` | Only when deploying to VPS | SSH username (e.g. `root` or `deploy`). |
| **Production VPS** | `VPS_SSH_KEY` | Only when deploying to VPS | Private SSH key (`~/.ssh/id_rsa` or dedicated deploy key). |
| **Production VPS** | `VPS_SSH_PORT` | Optional | SSH port (defaults to `22`). |
| **Production VPS** | `VPS_DEPLOY_DIR` | Optional | Deployment path on VPS (defaults to `/opt/lokalaku`). |
| **Database & Auth** | `POSTGRES_PASSWORD` | On VPS / Prod | Strong database password for production PostgreSQL. |
| **Database & Auth** | `REDIS_PASSWORD` | On VPS / Prod | Strong password for production Redis container. |
| **Database & Auth** | `JWT_SECRET` | On VPS / Prod | Random 32+ character string for signing JWT tokens. |

---

## 2. Option 1: Zero-Cost Tunnel Setup (Before Having a VPS)

Before you purchase a VPS, mobile APKs and web frontends need an HTTPS backend URL to communicate with.

### Step 1: Run your local backend with the tunnel profile
In your local repository root:
```bash
docker compose --profile tunnel up
```
Docker will start `postgres`, `redis`, `api`, and the `cloudflared` tunnel container.

### Step 2: Copy the generated HTTPS tunnel URL
Check the logs of `lokalaku_tunnel_dev`:
```bash
docker logs -f lokalaku_tunnel_dev
```
Look for the output line:
```
https://[random-string].trycloudflare.com
```

### Step 3: Add to GitHub Secrets
1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**.
2. Click **New repository secret**.
3. Name: `API_BASE_URL`
4. Value: `https://[random-string].trycloudflare.com` (no trailing slash).

Now, whenever GitHub Actions builds an Android APK or web app, it will automatically point to this URL.

---

## 3. Mobile App Android Signing Credentials

To compile release APKs and AABs in GitHub Actions, you need a release keystore.

### Step 1: Generate a Release Keystore (One-Time)
Run this command on your machine:
```bash
keytool -genkey -v -keystore lokalaku-release.jks \
  -alias lokalaku-release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```
Store the chosen passwords and alias securely.

> [!CAUTION]
> **NEVER** commit `lokalaku-release.jks` into the git repository. It is ignored by `.gitignore`. Keep a safe offline backup.

### Step 2: Encode the Keystore to Base64
```bash
# On macOS:
base64 -i lokalaku-release.jks | pbcopy

# On Linux:
base64 -w 0 lokalaku-release.jks
```

### Step 3: Add Secrets to GitHub
Go to **GitHub** → **Settings** → **Secrets and variables** → **Actions**:
* `ANDROID_KEYSTORE_BASE64`: Paste the base64 string.
* `KEYSTORE_PASSWORD`: Keystore password.
* `KEY_ALIAS`: `lokalaku-release`
* `KEY_PASSWORD`: Key password.

---

## 4. Linux VPS Setup (When Ready to Host Live)

Lokalaku is designed for a single low-cost Linux VPS (~$4–$5/month on Hetzner, DigitalOcean, IDCloudHost, etc.).

### Step 1: VPS Requirements
* **OS:** Ubuntu 22.04 LTS or Debian 12
* **Specs:** 1–2 vCPU, 2 GB RAM (minimum 1 GB)
* **Ports open:** 22 (SSH), 80 (HTTP), 443 (HTTPS)

### Step 2: Install Docker on the VPS
SSH into the server and run:
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

### Step 3: Prepare the Deployment Directory
```bash
sudo mkdir -p /opt/lokalaku
sudo chown -R $USER:$USER /opt/lokalaku
```

### Step 4: Generate SSH Deploy Key
On your local machine (or create a dedicated pair for GitHub Actions):
```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/lokalaku_deploy
```
1. Add the public key (`lokalaku_deploy.pub`) to `/home/user/.ssh/authorized_keys` on your VPS.
2. Add the private key (`lokalaku_deploy`) to GitHub Secrets as `VPS_SSH_KEY`.
3. Set `VPS_HOST` to your VPS IP and `VPS_USER` to your username.

### Step 5: Configure Production Environment on VPS
Create `/opt/lokalaku/.env` on the VPS:
```bash
POSTGRES_USER=lokalaku
POSTGRES_PASSWORD=<generate-strong-password>
POSTGRES_DB=lokalaku_prod
REDIS_PASSWORD=<generate-strong-password>
JWT_SECRET=<generate-random-32-char-string>
PORT=8080
```
You can generate secure random passwords using:
```bash
openssl rand -hex 32
```

---

## 5. Web Applications Deployment (Astro Website & Flutter Backoffice)

Lokalaku compiles two web applications during the `cd-web` pipeline:
1. **`apps/website` (Astro):** Public-facing static village directory and catalog served at root (`/`).
2. **`apps/backoffice_web` (Flutter Web):** Operator dashboard served under `/backoffice/`.

### Pre-VPS Staging: GitHub Pages
GitHub Pages provides free static hosting with zero vendor lock-in for early testing:
1. Go to your GitHub repository → **Settings** → **Pages**.
2. Under **Build and deployment** → **Source**, select **GitHub Actions**.
3. When `cd-web.yml` runs on push to `main`, it bundles both web apps and publishes them to `https://<organization>.github.io/<repo>/`.
4. The web applications connect to your backend via the injected `API_BASE_URL` (Cloudflare Tunnel or VPS domain).

### Production VPS: Static Web Root
When `VPS_HOST` is configured, `cd-web.yml` also synchronizes compiled static bundles to the VPS:
* Website: `${DEPLOY_DIR}/www/website`
* Backoffice: `${DEPLOY_DIR}/www/backoffice`

A lightweight Caddy or Nginx reverse proxy serves these directories with immutable 1-year caching for fingerprinted assets (`/_astro/*`, `/assets/*`) and immediate revalidation (`no-cache`) for entrypoint `index.html` files.

---

## 6. Summary Checklist Before Running First CD

- [ ] `API_BASE_URL` secret added in GitHub (Cloudflare Tunnel or production URL).
- [ ] GitHub Pages source set to **GitHub Actions** in repository settings (for web CD).
- [ ] `ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` added for mobile builds.
- [ ] (Optional) `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY` added when a production host is ready. If omitted, CD workflows publish Docker images to GHCR and web apps to GitHub Pages, gracefully skipping the VPS deploy step without error.

