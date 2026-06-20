# Pushing to GitHub - Step-by-Step Guide

This guide walks you through uploading this project to GitHub.

---

## Step 1: Create GitHub Account

If you don't have one:
1. Go to https://github.com/signup
2. Create account with email and password
3. Verify email address

---

## Step 2: Create New Repository on GitHub

1. Go to https://github.com/new
2. **Repository name:** `apache-reverse-proxy`
3. **Description:** "Modular Docker/Apache reverse proxy for self-hosted media servers"
4. **Visibility:** Choose `Public` or `Private`
5. **Initialize repository:** Leave unchecked (we have code already)
6. Click **Create repository**

---

## Step 3: Setup Git Locally

First, navigate to your project directory:

```bash
cd /mnt/user-data/outputs
```

### Initialize Git Repository

```bash
# Initialize git (if not already done)
git init

# Set your name and email
git config user.name "Your Name"
git config user.email "your.email@example.com"

# (Optional) Make it global:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Step 4: Add All Files

```bash
# Add all files to git
git add .

# View what will be committed
git status

# Should show all files in green (staged for commit)
```

---

## Step 5: Create Initial Commit

```bash
git commit -m "Initial commit: Apache reverse proxy with 15 services

- Complete Docker setup with docker-compose
- 15 pre-configured media server services
- Office 365 authentication support
- Dynamic menu system with icon management
- Let's Encrypt SSL/TLS automation
- Unraid native template
- Comprehensive documentation"
```

---

## Step 6: Add Remote Repository

Replace `YOUR_USERNAME` and `REPO_NAME` with your actual GitHub username and repository name:

```bash
# Option A: HTTPS (Password-based)
git remote add origin https://github.com/YOUR_USERNAME/apache-reverse-proxy.git

# Option B: SSH (Key-based) - More secure
git remote add origin git@github.com:YOUR_USERNAME/apache-reverse-proxy.git
```

### Verify Remote

```bash
git remote -v
# Should show:
# origin  https://github.com/YOUR_USERNAME/apache-reverse-proxy.git (fetch)
# origin  https://github.com/YOUR_USERNAME/apache-reverse-proxy.git (push)
```

---

## Step 7: Push to GitHub

### First Time Push

```bash
# Rename branch to 'main' (GitHub default)
git branch -M main

# Push everything to GitHub
git push -u origin main
```

**HTTPS Users:** Will be prompted for:
- Username: Your GitHub username
- Password: Your GitHub Personal Access Token

**Generate Personal Access Token** (instead of password):
1. Go to https://github.com/settings/tokens
2. Click "Generate new token"
3. Give it a name: "Git CLI"
4. Select scopes: `repo`, `write:packages`
5. Copy token and use as password

**SSH Users:** Must have SSH key configured:
```bash
# Generate SSH key (if needed)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to GitHub: https://github.com/settings/keys
cat ~/.ssh/id_ed25519.pub
```

---

## Step 8: Verify on GitHub

1. Go to https://github.com/YOUR_USERNAME/apache-reverse-proxy
2. You should see:
   - ✅ All files listed
   - ✅ README.md (or GITHUB-README.md) displayed
   - ✅ Initial commit shown

---

## Step 9: Optional - Rename Main README

If you used `GITHUB-README.md`, rename it on GitHub:

```bash
# Locally
mv GITHUB-README.md README.md
git add README.md
git rm --cached GITHUB-README.md
git commit -m "docs: rename to standard README.md"
git push
```

Or do it on GitHub:
1. Click on `GITHUB-README.md`
2. Click the pencil icon (Edit)
3. Click "Rename file" option
4. Change to `README.md`
5. Click "Commit changes"

---

## Step 10: Add Topics (Optional)

Help others discover your project:

1. Go to repository Settings
2. Scroll to "Topics"
3. Add relevant tags:
   - `docker`
   - `reverse-proxy`
   - `apache`
   - `media-server`
   - `self-hosted`
   - `ssl`
   - `lets-encrypt`
   - `sonarr`
   - `radarr`

---

## Step 11: Add Description (Optional)

1. Go to repository home
2. Click "Edit" next to repository name
3. Add description: "Modular Docker/Apache reverse proxy for self-hosted media servers with 15 services"
4. Add website URL (if you have one)
5. Click "Save"

---

## Going Forward

### Making Changes

```bash
# Make edits to files...

# Check what changed
git status

# Add changes
git add .
# or specific files:
git add filename.txt

# Commit
git commit -m "Short description of changes"

# Push to GitHub
git push
```

### Creating Branches

```bash
# Create feature branch
git checkout -b feature/authelia-support

# Make changes...
git add .
git commit -m "feat: add Authelia authentication support"
git push -u origin feature/authelia-support

# Create pull request on GitHub
# Go to repository and create PR from branch
```

### Creating Releases

```bash
# Create a tag
git tag -a v2.0.0 -m "Release version 2.0.0"

# Push tag to GitHub
git push origin v2.0.0

# GitHub automatically creates Release from tag
```

---

## Useful Git Commands

```bash
# View commit history
git log --oneline -10

# Undo last commit (before push)
git reset --soft HEAD~1

# See changes before committing
git diff

# View all branches
git branch -a

# Switch branches
git checkout main
git checkout feature/my-feature

# Update from GitHub
git pull

# View remote
git remote -v
```

---

## Troubleshooting

### "Repository not found"

```bash
# Check remote is correct
git remote -v

# If wrong, remove and re-add
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/apache-reverse-proxy.git
```

### "Permission denied"

**HTTPS:** Update credentials in git
```bash
git credential reject https://github.com
# Next push will prompt for new credentials
```

**SSH:** Check SSH key added to GitHub
```bash
ssh -T git@github.com
# Should say: "Hi YOUR_USERNAME! You've successfully authenticated..."
```

### "Branch already exists"

```bash
# Use different branch name
git branch -M main-v2
git push -u origin main-v2
```

---

## After Pushing

### Share Your Project

**On Reddit:**
```
Title: Apache Reverse Proxy - Complete Docker setup for self-hosted media servers (15 services)

r/selfhosted
r/unraid
r/docker
r/homelab
```

**On Twitter:**
```
Just released apache-reverse-proxy on GitHub! 🚀

Complete Docker/Apache reverse proxy for self-hosted media servers with:
✅ 15 services (Sonarr, Radarr, Jellyfin, etc.)
✅ Let's Encrypt SSL automation
✅ Office 365 authentication
✅ Unraid support

[GitHub link]

#selfhosted #docker #homelab
```

**On GitHub Discussions:**
- Announce in r/selfhosted
- Mention in relevant Discord servers
- Add to awesome-selfhosted list

---

## GitHub Repository Settings

### Branch Protection (Optional)

1. Settings → Branches
2. Add rule for `main`
3. Require pull request reviews
4. Require status checks to pass

### Enable GitHub Pages (Optional)

1. Settings → Pages
2. Source: Deploy from branch
3. Branch: `main`, folder: `/docs`
4. Your docs become a website!

### Add CI/CD (Future)

```bash
# Create workflow
mkdir -p .github/workflows
cat > .github/workflows/test.yml << 'EOF'
name: Docker Build

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build image
        run: docker-compose build
EOF
```

---

## Success! 🎉

Your project is now on GitHub! You can:

- ✅ Share the link
- ✅ Accept contributions
- ✅ Track issues
- ✅ Create releases
- ✅ Build community

---

## Next Steps

1. **Add a GitHub issue template** (Settings → Issues → Set up templates)
2. **Add a pull request template** (.github/pull_request_template.md)
3. **Create GitHub releases** (Releases tab)
4. **Enable discussions** (Settings → Discussion)
5. **Add GitHub Actions** for CI/CD

---

**Questions?** See [GitHub Help](https://docs.github.com)

Good luck! 🚀
