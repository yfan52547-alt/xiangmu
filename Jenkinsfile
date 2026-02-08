pipeline {
  agent any
  options { timestamps() }
  stages {
    stage('I-AM-RUNNING') {
      steps {
        echo 'I-AM-RUNNING'
      }
    }
  }
}

  environment {
    REGISTRY  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE = "rad-dev"
    REPO      = "gallery-test"
    ACR_CRED  = "acr-push"      // Jenkins 里保存的凭证ID（username/password）
  }

  stages {

    stage('00-PRINT') {
      steps {
        sh '''
          set -eux
          echo "=== JENKINSFILE IS RUNNING ==="
          echo "JOB_NAME=$JOB_NAME"
          echo "BUILD_NUMBER=$BUILD_NUMBER"
          echo "NODE_NAME=$NODE_NAME"
          echo "WORKSPACE=$WORKSPACE"
          pwd
          ls -la
        '''
      }
    }

    stage('01-CHECKOUT') {
      steps {
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
          echo "=== AFTER CHECKOUT ==="
          git log -1 --oneline
          ls -la
          if [ ! -f Dockerfile ]; then
            echo "ERROR: Dockerfile not found in repo root!"
            echo "If your Dockerfile is in another folder, tell me the path."
            exit 1
          fi
        '''
      }
    }

    stage('02-DOCKER-BUILD') {
      steps {
        sh '''
          set -eux
          echo "=== DOCKER VERSION ==="
          docker version
        '''
        script {
          def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          env.IMAGE_COMMIT = "${REGISTRY}/${NAMESPACE}/${REPO}:commit-${sha}"
          env.IMAGE_LATEST = "${REGISTRY}/${NAMESPACE}/${REPO}:latest"
        }
        sh '''
          set -eux
          echo "=== BUILD IMAGE ==="
          echo "IMAGE_COMMIT=$IMAGE_COMMIT"
          docker build -t "$IMAGE_COMMIT" .
          docker tag "$IMAGE_COMMIT" "$IMAGE_LATEST"
        '''
      }
    }

    stage('03-LOGIN-PUSH') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: "${ACR_CRED}",
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          sh '''
            set -eux
            echo "=== LOGIN REGISTRY ==="
            echo "$ACR_PASS" | docker login "$REGISTRY" -u "$ACR_USER" --password-stdin

            echo "=== PUSH IMAGES ==="
            docker push "$IMAGE_COMMIT"
            docker push "$IMAGE_LATEST"

            echo "$IMAGE_COMMIT" > build-info.txt
            echo "$IMAGE_LATEST" >> build-info.txt
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
