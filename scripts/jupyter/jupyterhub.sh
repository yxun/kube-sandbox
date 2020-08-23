#!/bin/bash

JUPYTERHUB_VERSION="0.9.0"
NAMESPACE="jhub"

function jupyterhub_install() {
    helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    helm repo update

    # minikube tunnel &
    kubectl create ns jhub
    helm install jupyterhub jupyterhub/jupyterhub --version ${JUPYTERHUB_VERSION} -n ${NAMESPACE} --values config.yaml
    kubectl get svc -n jhub
}

function main() {
    jupyterhub_install
}

main