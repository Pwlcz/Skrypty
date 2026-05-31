#!/bin/bash
set -euo pipefail

echo "==> Updating apt and installing dependencies..."
apt-get update && apt-get upgrade -y
apt-get install shellcheck shfmt python3-full zip -y