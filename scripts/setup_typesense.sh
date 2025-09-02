#!/usr/bin/env bash
set -euo pipefail

UNAME="$(uname)"

if [[ "$UNAME" == "Darwin" ]]; then
  echo "Detected macOS"
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Please install Homebrew first."
    exit 1
  fi
  if brew list --versions typesense-server >/dev/null 2>&1; then
    echo "Typesense already installed via Homebrew"
  else
    echo "Installing Typesense via Homebrew..."
    brew install typesense-server
  fi
elif [[ "$UNAME" == "Linux" ]]; then
  echo "Detected Linux"
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get not found. This script only supports Debian/Ubuntu."
    exit 1
  fi
  if dpkg -s typesense-server >/dev/null 2>&1; then
    echo "Typesense already installed via apt"
  else
    if ! ls /etc/apt/sources.list.d/typesense*.list >/dev/null 2>&1; then
      echo "Adding Typesense APT repo..."
      curl -s https://dl.typesense.org/typesense-server/apt/setup.sh | sudo bash
    else
      echo "Typesense APT repo already configured"
    fi
    sudo apt-get update
    sudo apt-get install -y typesense-server=0.25.1
  fi
else
  echo "Unsupported platform: $UNAME"
  exit 1
fi

printf '✅ Typesense setup complete\n'
