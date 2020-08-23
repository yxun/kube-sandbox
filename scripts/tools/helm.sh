#!/bin/bash

HELM_VERSION="v3.2.0"
OS="linux"
ARCH="amd64"

function helm_install() {
    curl -Lo helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${ARCH}.tar.gz
    tar -zxvf helm.tar.gz
    chmod +x ./${OS}-${ARCH}/helm
    mkdir -p ${HOME}/bin
    mv ./${OS}-${ARCH}/helm ${HOME}/bin/helm
    rm helm.tar.gz
    rm -r ${OS}-${ARCH}
    helm version
}

function helm_uninstall() {
    rm $(which helm)
}

function main() {
    helm_install
}

main