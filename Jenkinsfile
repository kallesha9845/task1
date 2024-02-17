pipeline {
    agent {
        kubernetes {
            defaultContainer 'kaniko'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
  - name: maven
    image: maven:3.9.6-eclipse-temurin-17
    command:
    - cat
    tty: true
  - name: helm
    image: alpine/helm
    command:
    - cat
    tty: true
    volumeMounts:
      - name: kubeconfig
        mountPath: /root/.kube
        readOnly: true
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
      - name: jenkins-docker-cfg
        mountPath: /kaniko/.docker
  volumes:
  - name: kubeconfig
    secret:
      secretName: kubeconfig
      key: kubeconfig
  - name: jenkins-docker-cfg
    projected:
      sources:
      - secret:
          name: docker-credentials
          items:
            - key: .dockerconfigjson
              path: config.json
"""
        }
    }
    environment {
      VERSION="1.0.16"
      IMAGE_PUSH_DESTINATION="docker.io/csnitsh/spring-crud-pm-app:${VERSION}"
    }
    stages {
        stage('lint') {
            steps {
                container('maven') {
                    sh 'mvn clean verify'
                }
            }
        }
        stage('Build with Kaniko') {
            steps {
                checkout scm
                container(name: 'kaniko', shell: '/busybox/sh') {
                    withEnv(['PATH+EXTRA=/busybox']) {
                        sh '''#!/busybox/sh
                            /kaniko/executor --context `pwd` --destination $IMAGE_PUSH_DESTINATION
                        '''
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                container('helm') {
                    sh 'echo "Deploying..."'
                    sh 'helm upgrade --install spring-crud-pm-app ./spring-crud-pm-app --set image.tag=$VERSION'
                }
            }
        }
        stage('Smoke Test') {
            steps {
                container('maven') {
                    echo 'Smoke Tests...'
                }
            }
        }
        stage('Tag'){
            steps{
                container('maven'){
                    sh 'echo "Tagging the commit with the version..."'
                    sh 'git tag $VERSION'
                    sh 'git push origin $VERSION'
                }
            }
        }
        stage('Promote to Production'){
            when{
                expression{
                    return env.BRANCH_NAME == 'main'
                }
            }
            steps{
                container('maven'){
                    sh 'echo "Promoting to Production..."'
                }
            }
        }
        stage('Smoke Test Production'){
            when{
                expression{
                    return env.BRANCH_NAME == 'main'
                }
            }
            steps{
                container('maven'){
                    echo 'Smoke Tests...'
                }
            }
        }
        stage('Notify'){
            steps{
                container('maven'){
                    sh 'echo "Notifying the team..."'
                }
            }
        }
    }
}