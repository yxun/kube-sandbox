#!/bin/bash

PROXY_PORT=8081

minikube start m01
kubectl proxy --port=${PROXY_PORT} &
