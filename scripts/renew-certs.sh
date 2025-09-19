#!/usr/bin/env bash
# No-op renewal hook to silence missing-script errors in development.
# Real deployments should provide Scripts/renew-certs.sh or set
# GATEWAY_CERT_RENEW_SCRIPT to an executable path.
exit 0

