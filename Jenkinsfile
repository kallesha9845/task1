pipeline {
    agent any
    environment { 
        application = 'spring-crud-pm-app'
        registry = 'docker.io'
        version = '1.0.0'
    }
    stages {
        stage('Update MySQL Password') {
            steps {
                echo 'Updating MySQL Password..'
                withCredentials([string(credentialsId: 'mysql-root-password', variable: 'MYSQL_ROOT_PASSWORD')]) {
                    sh """
                    sed "s/MYSQL_ROOT_PASSWORD/${MYSQL_ROOT_PASSWORD}/g" src/main/resources/application.properties > src/main/resources/application.properties.tmp
                    mv src/main/resources/application.properties.tmp src/main/resources/application.properties
                    """
                }
            }
        }
        stage('Build') {
            steps {
                echo 'Building..'
                echo '-Dmaven.test.skip=true to skip tests'
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