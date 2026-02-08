pipeline {
  agent any

  options { timestamps() }

  environment {
    REGISTRY  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE = "rad-dev"
    REPO      = "gallery-test"
    ACR_CRED  = "acr-push"   // 你 Jenkins 里 ACR 的 credentialsId
  }

  stages {
    stage('Sanity') {
      steps {
        sh '''
          set -eux
          echo "=== STAGES ARE RUNNING ==="
          whoami
          pwd
          ls -la
          docker version
        '''
      }
    }

    stage('Checkout') {
      steps {
        // 避免 checkout scm 在某些情况下拿到“脚本工作区”而不是源码工作区
        checkout([
          $class: 'GitSCM',
          branches: [[name: '*/main']],
          userRemoteConfigs: [[
            url: 'https://github.com/yfan52547-alt/xiangmu.git',
            credentialsId: 'github-token'
          ]]
        ])

        sh '''
          set -eux
          git log -1 --oneline
          ls -la
          test -f Dockerfile
        '''
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
          docker build -t "$IMAGE" .
        '''
      }
    }

    stage('Login & Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: "${ACR_CRED}",
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
