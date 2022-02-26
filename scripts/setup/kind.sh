#!/bin/bash

KIND_VERSION=$2
KIND_URL="https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-$(uname)-amd64"

function install_kind() {
  curl -Lo ./kind ${KIND_URL}
  chmod +x ./kind
  mkdir -p ${HOME}/bin
  mv ./kind ${HOME}/bin/kind
  kind --version
}

function uninstall_kind() {
  rm $(which kind)
}

function create_cluster() {
  echo "Create cluster test"
  kind create cluster --name test
  kind get clusters
  kind get nodes --name test
  kind get kubeconfig --name test
}

function delete_cluster() {
  kind delete cluster --name test
  kind get clusters
}

while getopts ":iucd" option; do
  set -x
  case ${option} in
    i) install_kind ;;
    u) uninstall_kind ;;
    c) create_cluster ;;
    d) delete_cluster ;;
    ?) echo "error: option -${OPTARG} is not implemented. Usage ./kind.sh [-iucd] args"; exit ;;
  esac
  set +x
done