<!-- markdownlint-disable MD013 -->
# Development

This page walks through the steps of building, deploying an Istio service mesh component using Sail operator in a running Kubernetes cluster.

## Requirements

| software | version  |                                                                link |
|:---------|:--------:|--------------------------------------------------------------------:|
| kubectl  | v1.23.0+ | [download](https://kubernetes.io/docs/tasks/tools/install-kubectl/) |
| go       |  v1.25   |                                  [download](https://golang.org/dl/) |
| docker   |  19.03+  |                        [download](https://docs.docker.com/install/) |

## Setup on Kind

For local development, a Kubernetes cluster can be created using [Kind](https://kind.sigs.k8s.io/).
You can also run the `kind_provisioner.sh` or the `main.sh` bash script (located in `infra/kind) to create a Kind cluster.

## End-to-end local development process on Kind

### Run the operator inside the cluster

```bash
# Create a Kind cluster
infra/kind/main.sh --skip-cleanup

# Build and push an image of Sail operator
# go to project istio-ecosystem/sail-operator
# Command: IMAGE={IMG_REPO}:{IMG_TAG} make docker-push
IMAGE="quay.io/yuaxu/sail-operator:latest" make docker-push

# Load the image into the Kind cluster
# Command: kind -n kind-testing load docker-image {IMG_REPO}:{IMG_TAG}
kind -n kind-testing load docker-image "${IMAGE}" 

# Install Sail operator with the custom image
# Command: IMAGE={IMG_REPO}:{IMG_TAG} make deploy
IMAGE="quay.io/yuaxu/sail-operator:latest" make deploy

# Check the operator logs
kubectl -n sail-operator logs deployments/sail-operator
```

* Replace `{IMG_REPO}` and `{IMG_TAG}` with your own repository and tag.
* The command `make docker-push` will also run `make docker-build` and `make build` (Go project compilation).
* The command `make deploy` also installs the custom resource definitions (CRDs) used by the Sail operator.
