pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    REGISTRY  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE = "rad-dev"
    REPO      = "gallery-test"
  }

  stages {
    stage('Sanity') {
      steps {
        sh '''
          set -ex
          whoami
          pwd
          git --version || true
          docker --version
        '''
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
        sh '''
          set -ex
          git log -1 --oneline
          ls -la
          test -f Dockerfile
        '''
      }
    }

    stage('Build Image') {
      steps {
        script {
          def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          env.TAG = "commit-${sha}"
          env.IMAGE = "${REGISTRY}/${NAMESPACE}/${REPO}:${env.TAG}"
        }
        sh '''
          set -ex
          echo "Building: ${IMAGE}"
          docker build -t ${IMAGE} .
          docker images | head
        '''
      }
    }

    stage('Login & Push to ACR') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'acr-push',   // ✅ 用你 Jenkins 里真实存在的
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          sh '''
            set -ex
            echo "$ACR_PASS" | docker login ${REGISTRY} -u "$ACR_USER" --password-stdin
            docker push ${IMAGE}
            echo "${IMAGE}" > build-info.txt
          '''
        }
        archiveArtifacts artifacts: 'build-info.txt', fingerprint: true
      }
    }
  }

  post {
    always {
      sh 'docker logout ${REGISTRY} >/dev/null 2>&1 || true'
    }
  }
}
