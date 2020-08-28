#!/bin/bash

VERSION="V0.16.1"

function cert-manager() {
    # kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.16.1/cert-manager.yaml
    # Using helm
    kubectl create namespace cert-manager
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version ${VERSION} \
    --set installCRDs=true \
    --set ingressShim.defaultIssuerName=letsencrypt-prod
}

function manager_uninstall() {
    helm uninstall cert-manager -n cert-manager
}

function main() {
    cert-manager
}

main