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

helm repo add jenkinsci https://charts.jenkins.io/
helm repo update
helm upgrade --install jenkins jenkinsci/jenkins --set controller.ingress.enabled=true


helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install mysql bitnami/mysql

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack
# helm upgrade --install prometheus-community/prometheus-mysql-exporter
