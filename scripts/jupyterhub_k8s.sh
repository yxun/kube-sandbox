helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

minikube tunnel &
kubectl create ns jhub
helm install jhub-0.9 jupyterhub/jupyterhub --version 0.9.0 -n jhub --values config.yaml
kubectl get svc -n jhub

