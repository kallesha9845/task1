#!/bin/bash
set -eou pipefail

kind create cluster --config ./kindcluster.yaml
kind get kubeconfig >kubeconfig

# Install Ingress Nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
# Wait for Ingress Nginx to be ready
kubectl wait --namespace ingress-nginx \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/component=controller \
	--timeout=90s

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install mysql bitnami/mysql --values values/mysql.yaml
MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace default mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)


helm repo add jenkinsci https://charts.jenkins.io/
helm repo update
helm upgrade --install jenkins jenkinsci/jenkins --values values/jenkns.yaml

# sed "s/MYSQL_ROOT_PASSWORD/${MYSQL_ROOT_PASSWORD}/g" src/main/resources/application.properties > src/main/resources/application.properties.tmp
# mv src/main/resources/application.properties.tmp src/main/resources/application.properties

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack
# helm upgrade --install prometheus-community/prometheus-mysql-exporter
