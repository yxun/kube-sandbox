#!/bin/bash

DASHBOARD_VERSION="v2.0.3"
DASHBOARD_URL="http://localhost:[localport]/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
PROXY_PORT="8081"
REMOTE_SSH="ssh yxu-blue"

function dashboard_install() {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
    sleep 40
    kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
}

function remote_proxy() {
    ${REMOTE_SSH} -f "kubectl proxy --port=${PROXY_PORT}"
    sleep 5
    ${REMOTE_SSH} "netstat -an | grep ${PROXY_PORT}"
}

function access_info() {
    echo "Access token"
    kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 -d
    echo
    echo "dashboard URL: ${DASHBOARD_URL}"
    echo
    echo "Remote access: check sshd AllowTcpForwarding yes"
    echo
    echo "Remote access ssh local forward: ssh -f -N -L [localport]:localhost:8081 yxu-blue"
}

function dashboard_uninstall() {
    ${REMOTE_SSH} "kill $(lsof -t -i:${PROXY_PORT})"
    kubectl delete clusterrolebinding default-admin
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
}

function main() {
    dashboard_install
    remote_proxy
    access_info
}

main