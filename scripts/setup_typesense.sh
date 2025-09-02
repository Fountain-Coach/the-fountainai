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
    echo "Attempting to add Typesense APT repo and install..."
    if curl -fsSL https://dl.typesense.org/typesense-server/apt/setup.sh | sudo bash; then
      sudo apt-get update
      sudo apt-get install -y typesense-server=0.25.1
    else
      echo "APT repo setup script not found, falling back to direct .deb install"
      TMP_DEB="/tmp/typesense-server-0.25.1-amd64.deb"
      curl -fLo "$TMP_DEB" https://dl.typesense.org/releases/0.25.1/typesense-server-0.25.1-amd64.deb
      STUB_SYSTEMCTL=0
      if ! command -v systemctl >/dev/null 2>&1 || ! pidof systemd >/dev/null 2>&1; then
        echo "Systemd not running; stubbing systemctl"
        if [ -x /usr/bin/systemctl ]; then
          sudo mv /usr/bin/systemctl /usr/bin/systemctl.real
          STUB_SYSTEMCTL=1
        fi
        sudo ln -sf /bin/true /usr/bin/systemctl
      fi
      sudo apt-get install -y "$TMP_DEB"
      if [[ "$STUB_SYSTEMCTL" -eq 1 ]]; then
        sudo rm /usr/bin/systemctl
        sudo mv /usr/bin/systemctl.real /usr/bin/systemctl
      fi
      rm -f "$TMP_DEB"
    fi
  fi
else
  echo "Unsupported platform: $UNAME"
  exit 1
fi

printf '✅ Typesense setup complete\n'
