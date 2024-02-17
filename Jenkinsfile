pipeline {
    agent any
    environment { 
        application = 'spring-crud-pm-app'
        registry = 'docker.io'
        version = '1.0.0'
    }
    stages {
        stage('Test') {
            steps {
                echo 'Testing..'
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                sh "docker build -f Dockerfile . --platform linux/amd64 -t $registry/$application:$version"
            }
        }
        stage('Push') {
            steps {
                echo "Pushing $registry/$application:$version to registry with credentials.."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "docker login -u $DOCKER_USER -p $DOCKER_PASS $registry"
                    sh "docker push $registry/$application:$version"
                }
            }
        }
        stage('Deploy') {
            agent {
                docker {
                    image 'bitnami/kubectl:latest'
                    args '-v kubeconfig:/.kube/config'
                }
            }
            steps {
                echo 'Deploying....'
                sh "kubectl apply -f k8s/deployment.yaml"
            }
        }
    }
}