#!/bin/bash -eux

echo '==> Post-Install: Configuring SSHD for Vagrant..'

echo '==> Turning off sshd DNS lookup to prevent timeout delay'
echo 'UseDNS no' >> /etc/ssh/sshd_config

echo '==> Disabling GSSAPI authentication to prevent timeout delay'
echo 'GSSAPIAuthentication no' >> /etc/ssh/sshd_config
