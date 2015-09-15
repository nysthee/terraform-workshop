#!/bin/bash
set -e

echo "Fetching Consul Template..."
cd /tmp
wget https://github.com/hashicorp/consul-template/releases/download/v0.10.0/consul-template_0.10.0_linux_amd64.tar.gz -O /tmp/consul-template.tar.gz

echo "Installing Consul Template..."
tar -xzvf /tmp/consul-template.tar.gz >/dev/null
sudo chmod +x consul-template_*/consul-template
sudo mv consul-template_*/consul-template /usr/local/bin/consul-template

echo "Installing Upstart service..."
sudo mv /tmp/consul-template.conf /etc/init/consul-template.conf

echo "Starting Consul Template..."
sudo start consul-template
