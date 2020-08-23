#!/bin/bash

USER="yxu"

function cgroup_revert() {
  cat /etc/*-release | grep release
  cat /proc/cmdline | grep systemd.unified_cgroup_hierarchy=0

  sudo dnf install grubby -y
  sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"
  sudo reboot
}

function docker_install() {
  sudo dnf install -y dnf-utils device-mapper-persistent-data lvm2

  sudo dnf config-manager --add-repo=https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf update -y && sudo dnf install -y docker-ce
  sudo groupadd docker
  sudo usermod -aG docker ${USER}
  sudo systemctl restart docker
  sudo systemctl enable docker
  newgrp docker
  sudo chown ${USER}:docker /var/run/docker.sock
  docker version
}

function docker_config() {
  mkdir -p /etc/docker

  sudo cat | sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

  sudo mkdir -p /etc/systemd/system/docker.service.d
  sudo systemctl daemon-reload
  sudo systemctl restart docker
  sudo systemctl enable docker
}

function docker_uninstall() {
  sudo systemctl disable docker
  sudo systemctl stop docker
  sudo dnf remove docker-ce -y
  sudo gpasswd -d ${USER} docker
  sudo groupdel docker
  sudo rm /etc/yum.repos.d/docker-ce.repo
}

function main() {
  # cgroupRevert if cgroup v2 is enabled in Fedora 31, revert back to cgroup v1
  # cgroup_revert

  docker_install
  docker_config
}

main