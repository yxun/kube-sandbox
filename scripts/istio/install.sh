#!/bin/bash

ISTIOCTL="bin/istioctl"

ISTIO_RELEASE="1.7.0"

function istio_install() {
    curl -L https://istio.io/downloadIstio | sh -
    pushd istio-${ISTIO_RELEASE}
    ${ISTIOCTL} install --set profile=demo
    sleep 30
    kubectl create ns bookinfo
    kubectl label namespace bookinfo istio-injection=enabled
    kubectl apply -n bookinfo -f samples/bookinfo/platform/kube/bookinfo.yaml
    sleep 30
    kubectl get services -n bookinfo
    kubectl get pod -n bookinfo
    kubectl exec -n bookinfo "$(kubectl get -n bookinfo pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -s productpage:9080/productpage | grep -o "<title>.*</title>"
    popd
}

function istio_uninstall() {
    pushd istio-${ISTIO_RELEASE}
    kubectl delete -n bookinfo -f samples/bookinfo/platform/kube/bookinfo.yaml
    sleep 10
    ${ISTIOCTL} manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -
    sleep 10
    kubectl delete namespace bookinfo
    kubectl delete namespace istio-system
    popd
}

function main() {
    istio_install
}

main