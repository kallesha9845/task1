#!/bin/bash
set -eou pipefail
export DOCKER_DEFAULT_PLATFORM=linux/arm64 
kind delete cluster
kind create cluster --config ./kindcluster.yaml
kind get kubeconfig --internal >config
kubectl delete secret kubeconfig || true
kubectl create secret generic kubeconfig --from-file=config
rm config 
# Install Ingress Nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
sleep 60
# Wait for Ingress Nginx to be ready
kubectl wait --namespace ingress-nginx \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/component=controller \
	--timeout=90s

# Install Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --values values/kube-prometheus-stack.yaml

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install mysql bitnami/mysql --values values/mysql.yaml
MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace default mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d)
# Since the db password changed we need to update the secret in application.properties
# Use sed to replace the password
sed "s/^spring.datasource.password=.*/spring.datasource.password=${MYSQL_ROOT_PASSWORD}/" src/main/resources/application.properties > src/main/resources/application.properties.tmp
mv src/main/resources/application.properties.tmp src/main/resources/application.properties

# Now db password is updated we can build the new docker image, push it to docker hub and deploy it to the cluster by updating the deployment.yaml with the right image 
VERSION="1.0.14"
APP_NAME="spring-crud-pm-app"
REGISTRY="docker.io/csnitsh/${APP_NAME}"
docker build -f Dockerfile . --platform linux/amd64 -t "${REGISTRY}:${VERSION}"
docker push "${REGISTRY}:${VERSION}"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl set image deployment/"${APP_NAME}" "${APP_NAME}"="${REGISTRY}:${VERSION}"
git add . && git commit --amend --no-edit && git push --force

# Create a secret for docker hub
dokcer-username="csnitsh"
docker-password="****"
docker-email="csnitish@gmail.com"
docker-server="https://index.docker.io/v1/"

kubectl create secret docker-registry docker-credentials \
    --docker-username=${dokcer-username}  \
    --docker-password=${docker-password} \
    --docker-email=${docker-email}
# kubectl create secret docker-registry docker-credentials \
#     --docker-username=${dokcer-username}  \
#     --docker-password=${docker-password} \
#     --docker-email=${docker-email} --dry-run=client -o jsonpath='{.data.\.dockerconfigjson}' | base64 -D > config.json
kubectl create secret docker-registry regcred \
--docker-server=${docker-server} \
--docker-username=${dokcer-username}  \
--docker-password=${docker-password} \
--docker-email=${docker-email}
# kubectl create secret generic regcred \
# --from-file=.dockerconfigjson=./config.json \
# --type=kubernetes.io/dockerconfigjson
rm config.json
# Install jenkins
helm repo add jenkinsci https://charts.jenkins.io/
helm repo update
helm upgrade --install jenkins jenkinsci/jenkins --values values/jenkins.yaml
