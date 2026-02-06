pipeline {
  agent any

  environment {
    REGISTRY  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE = "rad-dev"
    REPO      = "gallery-test"
  }

  stages {
    stage('Sanity') {
      steps {
        sh '''
          set -eux
          whoami
          pwd
          ls -la
          docker version
        '''
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
        sh 'git log -1 --oneline'
      }
    }

    stage('Build') {
      steps {
        script {
          def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          env.IMAGE = "${REGISTRY}/${NAMESPACE}/${REPO}:commit-${sha}"
        }
        sh '''
          set -eux
          test -f Dockerfile
          docker build -t "$IMAGE" .
        '''
      }
    }

    stage('Login & Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'acr-push',   // 你截图里叫 acr-push，不是 acr-login
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          sh '''
            set -eux
            echo "$ACR_PASS" | docker login "$REGISTRY" -u "$ACR_USER" --password-stdin
            docker push "$IMAGE"
            echo "$IMAGE" > build-info.txt
          '''
        }
        archiveArtifacts artifacts: 'build-info.txt', fingerprint: true
      }
    }
  }

  post {
    always {
      sh 'docker logout "$REGISTRY" >/dev/null 2>&1 || true'
    }
  }
}
