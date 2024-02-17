pipeline {
    agent any
    environment { 
        application = 'spring-crud-pm-app'
        namespace = 'csnitsh'
        registry = 'docker.io'
        version = '1.0.0'
    }
    stages {
        // stage('Update MySQL Password') {
        //     steps {
        //         echo 'Updating MySQL Password..'
        //         withCredentials([string(credentialsId: 'mysql-root-password', variable: 'MYSQL_ROOT_PASSWORD')]) {
        //             sh """
        //             sed "s/MYSQL_ROOT_PASSWORD/${MYSQL_ROOT_PASSWORD}/g" src/main/resources/application.properties > src/main/resources/application.properties.tmp
        //             mv src/main/resources/application.properties.tmp src/main/resources/application.properties
        //             """
        //         }
        //     }
        // }
        stage('Build') {
            agent {
                // Use the Kaniko executor image as the agent
                docker {
                    image 'gcr.io/kaniko-project/executor:latest'
                    // args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                echo 'Building..'
                // echo '-Dmaven.test.skip=true to skip tests'
                script {
                    // Define the Dockerfile path, relative to the workspace
                    def dockerfilePath = 'Dockerfile'
                    // Define the destination of the image
                    def destination = "$registry/$namespace/$application:$version"
                    // Run the Kaniko executor to build and push the Docker image
                    sh """
                    /kaniko/executor --dockerfile=${dockerfilePath} --destination=${destination} --context=dir://$(pwd)
                    """
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