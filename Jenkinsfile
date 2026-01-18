pipeline {
  agent any
environment {
    APP_NAME = "demo-web"
    IMAGE    = "demo-web:latest"
    WEB_PORT = "8088"
  }
stages {
stage('Checkout') {
      steps {
        // 拉取代码（非常重要）
        checkout scm
        sh 'ls -la'
      }
    }
stage('Build Docker Image') {
      steps {
        sh '''
          docker build -t ${IMAGE} .
        '''
      }
    }
stage('Deploy Container') {
      steps {
        sh '''
          set -e
          docker rm -f ${APP_NAME} || true
          docker run -d \
            --name ${APP_NAME} \
            -p ${WEB_PORT}:80 \
            ${IMAGE}
        '''
      }
    }
  }
}
