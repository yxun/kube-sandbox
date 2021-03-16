#!/bin/bash

function os_config() {
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
br_netfilter
EOF

    sudo sysctl --system
    lsmod | grep br_netfilter
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    sudo dnf remove zram-generator-defaults -y
    swapon --show
    sudo swapoff -a
    sudo sed -i 's/^\(.*swap.*\)$/#\1/' /etc/fstab
    # sudo reboot now

    sudo firewall-cmd --permanent --add-port=6443/tcp
    sudo firewall-cmd --permanent --add-port=2379-2380/tcp
    sudo firewall-cmd --permanent --add-port=10250/tcp
    sudo firewall-cmd --permanent --add-port=10251/tcp
    sudo firewall-cmd --permanent --add-port=10252/tcp
    sudo firewall-cmd --permanent --add-port=30000-32767/tcp
    #sudo firewall-cmd --permanent --add-port=10255/tcp
    #sudo firewall-cmd --permanent --add-port=8472/udp
    #sudo firewall-cmd --add-masquerade --permanent
    sudo systemctl restart firewalld
}

function kubeadm_install() {
    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

    sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    sudo systemctl enable --now kubelet

}

function crio_install() {
    CRIO_VERSION=1.20

    cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter

    sudo sysctl --system

    sudo dnf module enable cri-o:${CRIO_VERSION} -y
    sudo dnf install cri-o -y
    # /etc/sysconfig/kubelet
    ## KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint='unix:///var/run/crio/crio.sock' --runtime-request-timeout=5m

    sudo systemctl daemon-reload
    sudo systemctl restart crio
    sudo systemctl enable crio
}

function kubeadm_init() {
    sudo kubeadm init --apiserver-advertise-address=192.168.99.102 --pod-network-cidr=192.168.0.0/16

    mkdir -p $HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

function cni_setup() {
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
    kubectl get pods --all-namespaces
}

function single_node() {
    kubectl taint nodes --all node-role.kubernetes.io/master-
    #kubeadm token create --print-join-command
}


function setup_test() {
    curl -O https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.18.3/sonobuoy_0.18.3_linux_amd64.tar.gz
    tar -xvf sonobuoy_0.18.3_linux_amd64.tar.gz 

    cd k8s
    ./sonobuoy run --wait
    results=$(./sonobuoy retrieve)
    ./sonobuoy results $results
    ./sonobuoy delete --wait
}

function cleanup() {
    sudo kubeadm reset -f
    sudo rm -rf /var/lib/cni
    sudo rm -rf /etc/cni/net.d

    # kubectl config delete-cluster <cluser name>
    # kubectl config delete-context <context name>
    # kubectl config unset users.<user name>

    # kubectl drain <node name> --delete-local-data --force --ignore-daemonsets

    sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
    # reinstall docker is needed after cleanup iptables
    # kubectl delete node <node name>
}

function main() {
    os_config
    kubeadm_install
    kubeadm_init
    cni_setup
    single_node
    setup_test
}

main