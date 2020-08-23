#!/bin/bash

DASHBOARD_VERSION="v2.0.3"
DASHBOARD_URL="http://yxu-blue:8081/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
PROXY_PORT="8081"


function dashboard_install() {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
    sleep 40

    kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
    kubectl proxy --port=${PROXY_PORT}    
    sleep 5
    netstat -anp | grep ${PROXY_PORT}
}

function access_info() {
    echo "Access token"
    kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 -d

    echo "dashboard URL: ${DASHBOARD_URL}"
    echo "Remote access: check sshd AllowTcpForwarding yes"
    echo "Remote access ssh local forward: ssh -f -N -L [localport]:localhost:8081 yxu-blue"
}

function dashboard_uninstall() {
    kill $(lsof -t -i:${PROXY_PORT})
    kubectl delete clusterrolebinding default-admin
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
}

function main() {
    dashboard_install
    access_info
}

main