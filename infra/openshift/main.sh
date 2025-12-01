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

# Usage: ./main.sh flags
# Example: ./main.sh -d -v 4.19.19 -n my-cluster

# Exit immediately for non zero status
set -e
# Check unset variables
set -u
# Print commands
set -x

WD=$(dirname "$0")
WD=$(cd "$WD"; pwd)

AWS_PROFILE="openshift-service-mesh-dev"    # used by the installer and aws cli
INSTALLER_VERSION="4.19.19"                 # default installer version
INSTALLER_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${INSTALLER_VERSION}/openshift-install-linux.tar.gz"
CLUSTER_NAME="yuaxu"
CLUSTER_ASSETS="assets-${CLUSTER_NAME}"     # a new directory name used by the installer and Terraform configs
CONFIG_FILE="config/install-config.yaml"    # you can substitute values in the install-config.yaml.template file

while (( "$#" )); do
  case "$1" in
    -d)
      DOWNLOAD=true
      shift
    ;;
    -v)
    INSTALLER_VERSION=$2
    INSTALLER_URL="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${INSTALLER_VERSION}/openshift-install-linux.tar.gz"
    shift 2
    ;;
    -n)
    CLUSTER_NAME=$2
    CLUSTER_ASSETS="assets-${CLUSTER_NAME}"
    shift 2
    ;;
    --config)
    CONFIG_FILE=$2
    shift 2
    ;;
    --cleanup)
      CLEANUP=true
      shift
    ;;
    -*)
      echo "Error: Unsupported flag $1" >&2
      echo "Usage: $0 [-d] [-v] [-n] [--config] [--cleanup]"
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS+=("$1")
      shift
      ;;
  esac
done

set -- "${PARAMS[@]}" # restore positional parameters

# Download the installer
if [[ -n "${DOWNLOAD:-}" ]]; then
  echo "Downloading an installer..."
  echo
  curl --insecure --output openshift-install.tar.gz "${INSTALLER_URL}"
  tar -xzf openshift-install.tar.gz
  rm openshift-install.tar.gz
  chmod +x openshift-install
fi

# Create an asset directory
mkdir -p "${CLUSTER_ASSETS}"

if [[ -z "${CLEANUP:-}" ]]; then
  echo "Creating a cluster..."
  echo
  # Copy install-config file into the assets directory. The file name need to be install-config.yaml
  cp "${CONFIG_FILE}" "${CLUSTER_ASSETS}/install-config.yaml"
  sed -i "s:{{NAME_TAG}}:${CLUSTER_NAME}:g" "${CLUSTER_ASSETS}/install-config.yaml"

  ./openshift-install --dir="${WD}/${CLUSTER_ASSETS}" create cluster
  echo "Cluster creation completed."
else
  echo "Destroying the cluster..."
  echo
  ./openshift-install --dir="${WD}/${CLUSTER_ASSETS}" destroy cluster --log-level=debug
  rm "${CLUSTER_ASSETS}/.openshift_install.log"
  rmdir "${CLUSTER_ASSETS}"
  echo "Cleanup completed."
fi
