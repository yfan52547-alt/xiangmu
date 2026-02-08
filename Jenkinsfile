pipeline {
  agent any
stage('Sanity') {
  steps {
    sh '''
      set -eux
      echo "I AM RUNNING JENKINSFILE STAGES"
      whoami
      pwd
      ls -la
      docker version
    '''
  }
}

  environment {
    REGISTRY  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE = "rad-dev"
    REPO      = "gallery-test"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        sh 'ls -la'
        sh 'git log -1 --oneline'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          env.IMAGE = "${REGISTRY}/${NAMESPACE}/${REPO}:commit-${sha}"
        }

        sh '''
          set -eux
          docker version
          test -f Dockerfile
          docker build -t "$IMAGE" .
        '''
      }
    }

    stage('Push to ACR') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'acr-push',
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          sh '''
            set -eux
            echo "$ACR_PASS" | docker login "$REGISTRY" -u "$ACR_USER" --password-stdin
            docker push "$IMAGE"
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker logout "$REGISTRY" || true'
    }
  }
}
