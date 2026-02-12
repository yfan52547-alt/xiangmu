pipeline {
  agent any

  environment {
    REGISTRY   = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE  = "rad-dev"
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
          def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

          env.COMMIT_TAG = "commit-${sha}"
          env.IMAGE_COMMIT = "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.COMMIT_TAG}"

          sh """
            set -e
            echo "Build => ${env.IMAGE_COMMIT}"
            docker build --pull -t ${env.IMAGE_COMMIT} .
          """
        }
      }
    }

    stage('Manual Confirm Version') {
      steps {
        script {
          // 弹出输入框：输入 V.X.X
          def userInput = input(
            message: "准备推送到 ACR：${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}\\n请输入版本号（格式：V1.2.3）后继续：",
            ok: "确认并继续推送",
            parameters: [
              string(name: 'VERSION', defaultValue: 'V1.0.0', description: '版本号必须是 V数字.数字.数字，例如 V1.2.3')
            ]
          )

          // input 返回的是你填的字符串
          env.VERSION = "${userInput}".trim()

          // 严格校验：V数字.数字.数字
          if (!(env.VERSION ==~ /^V\\d+\\.\\d+\\.\\d+$/)) {
            error "版本号格式不正确：${env.VERSION}。请使用 V1.2.3 这种格式（大写V + 数字.数字.数字）"
          }

          env.IMAGE_VERSION = "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.VERSION}"

          // 给同一个 image 再打一个版本 tag（不重新 build）
          sh """
            set -e
            echo "Tagging => ${env.IMAGE_COMMIT}  ==>  ${env.IMAGE_VERSION}"
            docker tag ${env.IMAGE_COMMIT} ${env.IMAGE_VERSION}
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
            echo "\$ACR_PASS" | docker login ${REGISTRY} -u "\$ACR_USER" --password-stdin

            echo "Pushing => ${env.IMAGE_COMMIT}"
            docker push ${env.IMAGE_COMMIT}

            echo "Pushing => ${env.IMAGE_VERSION}"
            docker push ${env.IMAGE_VERSION}

            echo "${env.IMAGE_VERSION}" > build-info.txt
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
