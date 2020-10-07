#!/bin/bash

kubectl create ns db
kubectl apply -n db -f mysql-pv.yaml
sleep 10
kubectl apply -n db -f mysql-deployment.yaml
sleep 10

kubectl run -n db -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -ppassword
