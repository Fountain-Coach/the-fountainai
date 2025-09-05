#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."

# Load environment variables from .env if present
env_file="$REPO_ROOT/.env"
if [[ -f "$env_file" ]]; then
  set -a
  source "$env_file"
  set +a
fi

prompt_var() {
  local var="$1"
  local secret="$2"
  if [[ -z "${!var:-}" ]]; then
    if [[ "$secret" == "1" ]]; then
      read -s -p "Enter $var: " value
      echo
    else
      read -r -p "Enter $var: " value
    fi
    export "$var"="$value"
    read -r -p "Save $var to .env for future runs? [y/N]: " save
    if [[ "$save" =~ ^[Yy]$ ]]; then
      if [[ -f "$env_file" ]]; then
        grep -v "^${var}=" "$env_file" > "${env_file}.tmp" && mv "${env_file}.tmp" "$env_file"
      fi
      echo "$var=$value" >> "$env_file"
    fi
  fi
}

prompt_var "FOUNTAINSTORE_URL" 0
prompt_var "FOUNTAINSTORE_API_KEY" 1
prompt_var "OPENAI_API_KEY" 1

"$SCRIPT_DIR/boot.sh"
