#!/bin/bash

set -e

# Update packages
apt-get update

# Install XRDP
apt-get install -y xrdp

# Complete any pending package configuration
dpkg --configure -a
apt-get -f install -y

# Reload systemd
systemctl daemon-reload

# Enable and start XRDP
systemctl enable xrdp
systemctl restart xrdp

# Verify XRDP service
systemctl is-enabled xrdp
systemctl is-active xrdp
