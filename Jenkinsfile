pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    // 你的新 ACR（不要带 https://）
    REGISTRY  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE = "rad-dev"
    REPO      = "gallery-test"
  }

  stages {

    stage('Sanity') {
      steps {
        echo "Jenkinsfile is running!"
        sh 'whoami'
        sh 'pwd'
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
        sh 'git log -1 --oneline'
        sh 'ls -la'
      }
    }

    stage('Docker Precheck') {
      steps {
        sh '''
          set -e
          docker version
          docker info | head -n 50
        '''
      }
    }

    stage('Build Image') {
      steps {
        script {
          def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          env.TAG = "commit-${sha}"
          env.IMAGE = "${REGISTRY}/${NAMESPACE}/${REPO}:${env.TAG}"
          echo "IMAGE=${env.IMAGE}"
        }
        sh '''
          set -e
          test -f Dockerfile || (echo "Dockerfile not found in repo root!" && exit 1)
          docker build -t ${IMAGE} .
        '''
      }
    }

    stage('Login & Push to ACR') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'acr-login',       // 你 Jenkins 里 ACR 的凭据ID
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          sh '''
            set -e
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
      echo "Pipeline finished."
      sh 'docker logout ${REGISTRY} >/dev/null 2>&1 || true'
    }
  }
}
