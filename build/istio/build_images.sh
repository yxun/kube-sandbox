#!/bin/bash

# Copyright 2018 Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

WD=$(dirname "$0")
WD=$(cd "$WD" || exit; pwd)

# We run a local-registry in a docker container that KinD nodes pull from
# These values are must match what is in config/trustworthy-jwt.yaml
KIND_REGISTRY_NAME="kind-registry"
KIND_REGISTRY_PORT="5000"
KIND_REGISTRY_DIR="/etc/containerd/certs.d/localhost:${KIND_REGISTRY_PORT}"

function date_cmd() {
  case "$(uname)" in
    "Darwin")
      [ -z "$(which gdate)" ] && echo "gdate is required for OSX. Try installing coreutils from MacPorts or Brew."
      gdate "$@"
      ;;
    *)
      date "$@"
      ;;
  esac
}

# Output a message, with a timestamp matching istio log format
function log() {
  echo -e "$(date_cmd -u '+%Y-%m-%dT%H:%M:%S.%NZ')\t$*"
}

# Download and unpack istio release artifacts.
function download_untar_istio_release() {
  local url_path=${1}
  local tag=${2}
  local dir=${3:-.}
  # Download artifacts
  LINUX_DIST_URL="${url_path}/istio-${tag}-linux.tar.gz"

  wget  -q "${LINUX_DIST_URL}" -P "${dir}"
  tar -xzf "${dir}/istio-${tag}-linux.tar.gz" -C "${dir}"
}

# Creates a local registry for kind nodes to pull images from. Expects that the "kind" network already exists.
function setup_kind_registry() {
  # create a registry container if it not running already
  running="$(docker inspect -f '{{.State.Running}}' "${KIND_REGISTRY_NAME}" 2>/dev/null || true)"
  if [[ "${running}" != 'true' ]]; then
      docker run \
        -d --restart=always -p "${KIND_REGISTRY_PORT}:5000" --name "${KIND_REGISTRY_NAME}" \
        registry:2

    # Allow kind nodes to reach the registry
    docker network connect "kind" "${KIND_REGISTRY_NAME}"
  fi

  # https://docs.tilt.dev/choosing_clusters.html#discovering-the-registry
  for cluster in $(kind get clusters); do
    # TODO get context/config from existing variables
    if [[ "${DEVCONTAINER}" ]]; then
      kind export kubeconfig --name="${cluster}" --internal
    else
      kind export kubeconfig --name="${cluster}"
    fi
    for node in $(kind get nodes --name="${cluster}"); do
      docker exec "${node}" mkdir -p "${KIND_REGISTRY_DIR}"
      cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${KIND_REGISTRY_DIR}/hosts.toml"
[host."http://${KIND_REGISTRY_NAME}:5000"]
EOF
    
      kubectl annotate node "${node}" "kind.x-k8s.io/registry=kind-registry:${KIND_REGISTRY_PORT}" --overwrite;
    done

    # Document the local registry
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${KIND_REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
  done
}

function build_images() {

  # Build just the images needed for tests
  targets="docker.pilot docker.proxyv2 docker.ztunnel docker.install-cni "

  arch="linux/amd64"
  if [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]]; then
      arch="linux/arm64"
  fi

  DOCKER_ARCHITECTURES="${arch}"  DOCKER_BUILD_VARIANTS="${VARIANT:-default}" DOCKER_TARGETS="${targets}" "${WD}"/docker.sh --push
}
