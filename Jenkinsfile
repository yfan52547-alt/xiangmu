pipeline {
  agent any

  environment {
    REPO_PATH  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com/rad-dev/gallery-test"
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
          // 解析 REPO_PATH
          def parts = env.REPO_PATH.tokenize('/')
          if (parts.size() < 3) {
            error "REPO_PATH 格式不正确，应为：<registry>/<namespace>/<repo>，当前：${env.REPO_PATH}"
          }

          env.REGISTRY   = parts[0]
          env.NAMESPACE  = parts[1]
          env.IMAGE_NAME = parts[2]

          // 获取 Git 提交 ID
          def sha = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
          ).trim()

          env.IMAGE_TAG = "commit-${sha}"
          env.IMAGE = "${env.REGISTRY}/${env.NAMESPACE}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"

          // 打印构建信息
          echo "=== Build Info ==="
          echo "REPO_PATH   : ${env.REPO_PATH}"
          echo "REGISTRY    : ${env.REGISTRY}"
          echo "NAMESPACE   : ${env.NAMESPACE}"
          echo "IMAGE_NAME  : ${env.IMAGE_NAME}"
          echo "IMAGE_TAG   : ${env.IMAGE_TAG}"
          echo "FINAL IMAGE : ${env.IMAGE}"
          echo "==============="

          // 构建 Docker 镜像
          docker build --pull -t ${env.IMAGE} .
        }
      }
    }

    stage('Input Version for Tagging') {
      steps {
        script {
          // 等待用户输入版本号
          env.VERSION = input(
            message: 'Please input the version (e.g., V1.0.0):',
            parameters: [
              string(defaultValue: '', description: 'Enter version', name: 'VERSION_TAG')
            ]
          )
          
          // 确保版本号是有效的
          if (!env.VERSION) {
            error "Version is required to push the image."
          }

          // 更新镜像标签
          env.IMAGE_TAG = "v${env.VERSION}"
          env.IMAGE = "${env.REGISTRY}/${env.NAMESPACE}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
          
          echo "New Image Tag: ${env.IMAGE_TAG}"
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

