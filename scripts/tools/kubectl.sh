#!/bin/bash

KUBECTL_VERSION="v1.18.0"
OS="linux"
ARCH="amd64"

function kubectl_install() {
    curl -Lo ./kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}/kubectl
    chmod +x ./kubectl
    mkdir -p ${HOME}/bin
    mv ./kubectl ${HOME}/bin/kubectl
    kubectl version --client
}

function kubectl_uninstall() {
    rm $(which kubectl)
}

function main() {
    kubectl_install
}

main