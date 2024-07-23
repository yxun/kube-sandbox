#/bin/bash

set -e
set -x

NAME=istio-testing
DORP="podman"
IMAGE=""
LOAD_BALANCER_RANGE="255.70-255.84"

infomsg() {
  echo "[INFO] ${1}"
}

helpmsg() {
  cat <<HELP
This script will create a single node KinD cluster with metallb enabled.
Options:
-dorp|--docker-or-podman <docker|podman>
  What to use when running kind.
  Default: podman
-i|--image
  Image of the kind cluster. Defaults to latest kind image if not specified.
-lbr|--load-balancer-range
  Range for the metallb load balancer.
  Default: 255.70-255.84
-n|--name
  Name of the kind cluster
  Default: istio-testing
HELP
}

# process command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -dorp|--docker-or-podman)     DORP="$2";                    shift;shift; ;;
    -i|--image)                   IMAGE="$2";                   shift;shift; ;;
    -lbr|--load-balancer-range)   LOAD_BALANCER_RANGE="$2";     shift;shift; ;;
    -n|--name)                    NAME="$2";                    shift;shift; ;;
    -h|--help)                    helpmsg;                      exit 1       ;;
  esac
done

# Find the kind executable
KIND_EXE=`which kind`
if [ -x "${KIND_EXE}" ]; then
  echo "kind executable: ${KIND_EXE}"
else
  echo "Cannot find the kind executable. You must install it in your PATH. For details, see: https://kind.sigs.k8s.io/docs/user/quick-start"
  exit 1
fi

# Find the kubectl executable
KUBECTL_EXE=`which kubectl`
if [  -x "${KUBECTL_EXE}" ]; then
  echo "Kubectl executable: ${KUBECTL_EXE}"
else
  echo "Cannot find the kubectl executable. You must install it in your PATH."
  exit 1
fi

start_kind() {
  infomsg "Kind cluster to be created with name [${NAME}]"
  NODE_IMAGE_LINE=${IMAGE:+image: ${IMAGE}}
  cat <<EOF | ${KIND_EXE} create cluster --name "${NAME}" --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: ipv4
nodes:
  - role: control-plane
    ${NODE_IMAGE_LINE}
  - role: worker
    ${NODE_IMAGE_LINE}
EOF
}

config_metallb() {
  infomsg "Creating Kind LoadBalancer via MetaLLB"

  ${KUBECTL_EXE} apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

  local subnet
  if [ "${DORP}" == "podman" ]; then
    subnet=$(podman network inspect kind --format '{{ (index .Subnets 1).Subnet }}' 2>/dev/null)
  fi

  if [ -z "$subnet" ]; then
    infomsg "There does not appear to be any IPv4 subnets configured"
    exit 1
  fi

  infomsg "Wait for MetaLLB controller to be ready"
  ${KUBECTL_EXE} rollout status deployment controller -n metallb-system
  ${KUBECTL_EXE} rollout status daemonset speaker -n metallb-system

  local subnet_trimmed
  subnet_trimmed=$(echo ${subnet} | sed -E 's/([0-9]+\.[0-9]+)\.[0-9]+\..*/\1/')
  local first_ip
  first_ip="${subnet_trimmed}.$(echo "${LOAD_BALANCER_RANGE}" | cut -d '-' -f 1)"
  local last_ip
  last_ip="${subnet_trimmed}.$(echo "${LOAD_BALANCER_RANGE}" | cut -d '-' -f 2)"
  infomsg "LoadBalancer IP Address pool: ${first_ip}-${last_ip}"
  cat <<LBPOOL | ${KUBECTL_EXE} apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  namespace: metallb-system
  name: config
spec:
  addresses:
  - ${first_ip}-${last_ip}
LBPOOL

  cat <<LBAD | ${KUBECTL_EXE} apply -f -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  namespace: metallb-system
  name: l2config
spec:
  ipAddressPools:
  - config
LBAD
}

start_kind
config_metallb

infomsg "KinD cluster '${NAME}' created successfully with metallb loadbalancer"
