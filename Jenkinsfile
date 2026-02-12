pipeline {
  agent any

  environment {
    // 请确保这里填的是你控制台仓库页面提供的完整路径
    REPO_PATH  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com/yiyi-clound/gallery-test"
    REGISTRY   = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    IMAGE_NAME = "gallery-test"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        script {
          // 解析 REGISTRY / NAMESPACE / IMAGE_NAME
          def parts = env.REPO_PATH.tokenize('/')
          if (parts.size() < 3) {
            error "REPO_PATH 格式不正确，应为：<registry>/<namespace>/<repo>，当前：${env.REPO_PATH}"
          }

          env.REGISTRY   = parts[0]
          env.NAMESPACE  = parts[1]
          env.IMAGE_NAME = parts[2]

          // 生成 tag
          def sha = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
          ).trim()

          env.IMAGE_TAG = "commit-${sha}"
          env.IMAGE = "${env.REGISTRY}/${env.NAMESPACE}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"

          sh """
            set -e
            echo "=== Build Info ==="
            echo "REPO_PATH   : ${env.REPO_PATH}"
            echo "REGISTRY    : ${env.REGISTRY}"
            echo "NAMESPACE   : ${env.NAMESPACE}"
            echo "IMAGE_NAME  : ${env.IMAGE_NAME}"
            echo "IMAGE_TAG   : ${env.IMAGE_TAG}"
            echo "FINAL IMAGE : ${env.IMAGE}"
            echo "==============="

            docker version
            docker build --pull -t ${env.IMAGE} .
          """
        }
      }
    }

    stage('Push to ACR') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'acr-push',
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          sh """
            set -e
            echo "=== Login & Push ==="
            echo "Login Registry: ${env.REGISTRY}"
            echo "Push Image    : ${env.IMAGE}"

            echo "\$ACR_PASS" | docker login ${env.REGISTRY} -u "\$ACR_USER" --password-stdin

            # 可选：先显示本地镜像是否存在
            docker images | head -n 20

            docker push ${env.IMAGE}

            echo "${env.IMAGE}" > build-info.txt
            echo "Pushed: ${env.IMAGE}"
          """
        }
        archiveArtifacts artifacts: 'build-info.txt', fingerprint: true
      }
    }
  }

  post {
    always {
      echo "Pipeline finished."
    }
  }
}
