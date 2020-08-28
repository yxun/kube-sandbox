#!/bin/bash

JUPYTERHUB_VERSION="0.9.0"
NAMESPACE="jhub"

function jupyterhub_install() {
    kubectl apply -f ./pvc.yaml
    sleep 10
    helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    helm repo update

    kubectl create ns ${NAMESPACE}
    helm install jupyterhub jupyterhub/jupyterhub --version ${JUPYTERHUB_VERSION} -n ${NAMESPACE} --values config.yaml
    sleep 40
    kubectl get svc -n ${NAMESPACE}
}

function jupyterhub_uninstall() {
    helm uninstall jupyterhub -n ${NAMESPACE}
    kubectl delete -f ./pvc.yaml
    kubectl delete ns jhub
}

function main() {
    jupyterhub_install 
}

main