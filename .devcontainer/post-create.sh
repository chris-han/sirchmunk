#!/bin/bash
# Post-create setup script for GitHub Codespaces / devcontainer
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    build-essential \
    poppler-utils \
    pandoc \
    tesseract-ocr \
    ffmpeg

# Install ripgrep
RG_VERSION="14.1.1"
echo "==> Installing ripgrep ${RG_VERSION}..."
curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep_${RG_VERSION}-1_amd64.deb" \
    -o /tmp/rg.deb
sudo dpkg -i /tmp/rg.deb
rm /tmp/rg.deb

# Install ripgrep-all
RGA_VERSION="v0.10.10"
echo "==> Installing ripgrep-all ${RGA_VERSION}..."
curl -fsSL "https://github.com/phiresky/ripgrep-all/releases/download/${RGA_VERSION}/ripgrep_all-${RGA_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    -o /tmp/rga.tar.gz
tar -xzf /tmp/rga.tar.gz -C /tmp
sudo cp /tmp/ripgrep_all-*/rga /usr/local/bin/
sudo cp /tmp/ripgrep_all-*/rga-preproc /usr/local/bin/
rm -rf /tmp/rga.tar.gz /tmp/ripgrep_all-*

echo "==> Installing Python dependencies..."
pip install --upgrade pip
pip install \
    -r "${REPO_ROOT}/requirements/core.txt" \
    -r "${REPO_ROOT}/requirements/web.txt" \
    -r "${REPO_ROOT}/requirements/mcp.txt"

echo "==> Installing Sirchmunk package (editable)..."
pip install -e "${REPO_ROOT}[mcp,web]"

echo "==> Installing frontend dependencies..."
cd "${REPO_ROOT}/web"
npm ci

echo "==> Initialising Sirchmunk workspace..."
mkdir -p "${REPO_ROOT}/.sirchmunk"
sirchmunk init --work-path "${REPO_ROOT}/.sirchmunk" 2>/dev/null || true

# Copy env template if not present
if [ ! -f "${REPO_ROOT}/.sirchmunk/.env" ]; then
    cp "${REPO_ROOT}/config/env.example" "${REPO_ROOT}/.sirchmunk/.env"
    # Point workspace to repo-local directory
    sed -i "s|SIRCHMUNK_WORK_PATH=.*|SIRCHMUNK_WORK_PATH=${REPO_ROOT}/.sirchmunk|" \
        "${REPO_ROOT}/.sirchmunk/.env"
fi

echo ""
echo "======================================================"
echo " Sirchmunk devcontainer is ready!"
echo ""
echo " Before starting, set your LLM credentials:"
echo "   \$EDITOR .sirchmunk/.env"
echo ""
echo " Start the web server:"
echo "   sirchmunk web serve --host 0.0.0.0 --port 8584"
echo ""
echo " Or run the frontend dev server separately:"
echo "   cd web && npm run dev   # http://localhost:3000"
echo "======================================================"
