#!/bin/bash

function ingress_controller() {
    # kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.34.1/deploy/static/provider/baremetal/deploy.yaml
    # Using helm
    kubectl create namespace ingress-nginx
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx

    kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

    POD_NAMESPACE=ingress-nginx
    POD_NAME=$(kubectl get pods -n $POD_NAMESPACE -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -it $POD_NAME -n $POD_NAMESPACE -- /nginx-ingress-controller --version
}

function ingress_uninstall() {
    helm uninstall ingress-nginx -n ingress-nginx
}

function main() {
    ingress_controller 
}

main