#!/bin/bash
set -Eeuo pipefail

apt-get update

# Codex and Claude Code use bubblewrap for their Linux sandboxes.
# Claude Code also uses socat to proxy sandbox network traffic.
apt-get install -y \
  build-essential \
  bubblewrap \
  ca-certificates \
  curl \
  file \
  git \
  htop \
  jq \
  pkg-config \
  procps \
  python3 \
  python3-pip \
  python3-venv \
  ripgrep \
  rsync \
  socat \
  unzip \
  zip

# Since we are using snap, the aws-cli will be automatically updated.
snap install aws-cli --classic
