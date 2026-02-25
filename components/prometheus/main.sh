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

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update

kubectl create namespace monitoring
kubectl config set-context --current --namespace=sail-operator

# serviceMonitorSelectorNilUsesHelmValues=false allows Prometheus to discover ServiceMonitors across all namespaces

helm install kind-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.service.nodePort=30000 \
  --set prometheus.service.type=NodePort \
  --set grafana.service.nodePort=31000 \
  --set grafana.service.type=NodePort \
  --set alertmanager.service.nodePort=32000 \
  --set alertmanager.service.type=NodePort \
  --set prometheus-node-exporter.service.nodePort=32001 \
  --set prometheus-node-exporter.service.type=NodePort

kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get servicemonitors -n monitoring

# creating a ClusterRoleBinding for the service account to allow access to metrics

export TOKEN=$(kubectl create token sail-operator -n sail-operator)
