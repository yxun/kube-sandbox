#!/bin/bash

sudo kubeadm reset -f
sudo rm -rf /var/lib/cni
sudo rm -rf /etc/cni/net.d

# kubectl config delete-cluster <cluser name>
# kubectl config delete-context <context name>
# kubectl config unset users.<user name>

# kubectl drain <node name> --delete-local-data --force --ignore-daemonsets

sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

# kubectl delete node <node name>

