#!/bin/bash

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

# Usage: ./main.sh TARGET
# Example: ./main.sh --skip-cleanup

WD=$(dirname "$0")
WD=$(cd "$WD"; pwd)

# COMMON_SCRIPTS contains the directory this file is in.
COMMON_SCRIPTS=$(dirname "${BASH_SOURCE:-$0}")

# Exit immediately for non zero status
set -e
# Check unset variables
set -u
# Print commands
set -x

# shellcheck source=common/scripts/kind_provisioner.sh
source "${COMMON_SCRIPTS}/kind_provisioner.sh"

TOPOLOGY=SINGLE_CLUSTER
NODE_IMAGE="kindest/node:v1.32.0"
KIND_CONFIG=""
CLUSTER_TOPOLOGY_CONFIG_FILE="${COMMON_SCRIPTS}/config/multicluster.json"
CLUSTER_NAME="${CLUSTER_NAME:-kind-testing}"

while (( "$#" )); do
  case "$1" in
    # Node images can be found at https://github.com/kubernetes-sigs/kind/releases
    # For example, kindest/node:v1.32.0
    --node-image)
      NODE_IMAGE=$2
      shift 2
    ;;
    # Config for enabling different Kubernetes features in KinD (see prow/config{endpointslice.yaml,trustworthy-jwt.yaml}).
    --kind-config)
    KIND_CONFIG=$2
    shift 2
    ;;
    --skip-cleanup)
      SKIP_CLEANUP=true
      shift
    ;;
    --topology)
      case $2 in
        # TODO(landow) get rid of MULTICLUSTER_SINGLE_NETWORK after updating Prow job
        SINGLE_CLUSTER | MULTICLUSTER_SINGLE_NETWORK | MULTICLUSTER | AMBIENT_MULTICLUSTER )
          TOPOLOGY=$2
          echo "Running with topology ${TOPOLOGY}"
          ;;
        *)
          echo "Error: Unsupported topology ${TOPOLOGY}" >&2
          exit 1
          ;;
      esac
      shift 2
    ;;
    --topology-config)
      CLUSTER_TOPOLOGY_CONFIG_FILE="${COMMON_SCRIPTS}/${2}"
      shift 2
    ;;
    -*)
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS+=("$1")
      shift
      ;;
  esac
done

# Default IP family of the cluster is IPv4
KIND_IP_FAMILY="ipv4"
export IP_FAMILIES="${IP_FAMILIES:-IPv4}"
if [[ "$IP_FAMILIES" == "IPv6" ]]; then
   KIND_IP_FAMILY="ipv6"
elif [[ "$IP_FAMILIES" =~ "IPv6" ]] && [[ "$IP_FAMILIES" =~ "IPv4" ]]; then
   KIND_IP_FAMILY="dual"
fi
export KIND_IP_FAMILY

export ARTIFACTS="${ARTIFACTS:-$(mktemp -d)}"
export DEFAULT_CLUSTER_YAML="${COMMON_SCRIPTS}/config/default.yaml"

if [[ "${TOPOLOGY}" == "SINGLE_CLUSTER" ]]; then
  echo "setup kind cluster" 
  setup_kind_cluster_retry "${CLUSTER_NAME}" "${NODE_IMAGE}" "${KIND_CONFIG}"
else
  echo "load cluster topology"
  load_cluster_topology "${CLUSTER_TOPOLOGY_CONFIG_FILE}"
  echo "setup kind clusters"
  setup_kind_clusters "${NODE_IMAGE}" "${KIND_IP_FAMILY}"

  TOPOLOGY_JSON=$(cat "${CLUSTER_TOPOLOGY_CONFIG_FILE}")
  for i in $(seq 0 $((${#CLUSTER_NAMES[@]} - 1))); do
    CLUSTER="${CLUSTER_NAMES[i]}"
    KCONFIG="${KUBECONFIGS[i]}"
    TOPOLOGY_JSON=$(set_topology_value "${TOPOLOGY_JSON}" "${CLUSTER}" "meta.kubeconfig" "${KCONFIG}")
  done
  RUNTIME_TOPOLOGY_CONFIG_FILE="${ARTIFACTS}/topology-config.json"
  echo "${TOPOLOGY_JSON}" > "${RUNTIME_TOPOLOGY_CONFIG_FILE}"
fi

