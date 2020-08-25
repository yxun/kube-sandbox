#!/bin/bash

JUPYTERHUB_VERSION="0.9.0"
NAMESPACE="jhub"
PROXY_PORT="8081"
REMOTE_SSH="ssh yxu-blue"
HUB_URL="http://localhost:[localport]/api/v1/namespaces/${NAMESPACE}/services/http:hub:8081/proxy/"

function jupyterhub_install() {
    kubectl apply -f ./pv_standard.yaml
    sleep 10
    helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
    helm repo update

    kubectl create ns ${NAMESPACE}
    helm install jupyterhub jupyterhub/jupyterhub --version ${JUPYTERHUB_VERSION} -n ${NAMESPACE} --values config.yaml
    sleep 40
    kubectl get svc -n ${NAMESPACE}
}

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

function cert-manager() {
    # kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.16.1/cert-manager.yaml
    # Using helm
    kubectl create namespace cert-manager
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v0.16.1 \
    --set installCRDs=true \
    --set ingressShim.defaultIssuerName=letsencrypt-prod
}

function access_info() {
    echo
    echo "hub URL: ${HUB_URL}"
    echo
    echo "Remote access: check sshd AllowTcpForwarding yes"
    echo
    echo "Remote access ssh local forward: ssh -f -N -L [localport]:localhost:8081 yxu-blue"
}

function jupyterhub_uninstall() {
    helm uninstall jupyterhub -n ${NAMESPACE}
    kubectl delete -f ./pv_standard.yaml
    kubectl delete ns jhub
}

function main() {
    jupyterhub_install
    access_info
}

main