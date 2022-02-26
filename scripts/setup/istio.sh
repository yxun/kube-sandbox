#!/bin/bash

TAG_NAME=$2
REPO_URL="https://github.com/istio/istio.git"

function clone_repo() {
    git clone --branch ${TAG_NAME} ${REPO_URL}
    pushd istio
    git switch -c ${TAG_NAME}
    git branch -v
    popd
}

function build_default() {
    pushd istio
    make default
    popd
}

function delete_build() {
    pushd istio
    make clean
    popd
}

while getopts ":cbd" option; do
  set -x
  case ${option} in
    c) clone_repo ;;
    b) build_default ;;
    d) delete_build ;;
    ?) echo "error: option -${OPTARG} is not implemented. Usage ./istio.sh [-cbd] args"; exit ;;
  esac
  set +x
done
