pipeline {
  agent any

  // 可选：允许运行时覆盖命名空间（默认自动从 REPO_PATH 解析）
  parameters {
    string(name: 'NAMESPACE_OVERRIDE', defaultValue: '', description: '可选：手动覆盖 ACR 命名空间；留空则从 REPO_PATH 自动解析')
  }

  environment {
    // ===== 你需要改这里：把 REPO_PATH 换成你控制台里 “仓库地址/公网地址” 对应的完整路径 =====
    // 例：crpi-xxxx.cn-hangzhou.personal.cr.aliyuncs.com/<namespace>/gallery-test
    REPO_PATH  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com/请把这里改成真实namespace/gallery-test"

    // registry 主机将从 REPO_PATH 自动解析
    // 镜像名也从 REPO_PATH 自动解析（最后一段）
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

          // 允许手动覆盖命名空间（比如你想临时测试）
          if (params.NAMESPACE_OVERRIDE?.trim()) {
            env.NAMESPACE = params.NAMESPACE_OVERRIDE.trim()
          }

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
