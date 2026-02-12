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
          def userInput = input(
            message: "请输入版本号（允许：V1.1 或 V1.1.2）",
            ok: "确认",
            parameters: [
              string(name: 'VERSION', defaultValue: 'V1.0', description: '格式：V数字.数字 或 V数字.数字.数字')
            ]
          )

          env.VERSION = "${userInput}".trim()

          // 允许：V1.1 或 V1.1.2
          if (!(env.VERSION ==~ /^V\\d+\\.\\d+(\\.\\d+)?$/)) {
            error "版本号格式错误：${env.VERSION}。允许格式：V1.1 或 V1.1.2"
          }

          env.IMAGE_VERSION = "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.VERSION}"

          sh """
            set -e
            echo "Tagging => ${env.IMAGE_COMMIT} -> ${env.IMAGE_VERSION}"
            docker tag ${env.IMAGE_COMMIT} ${env.IMAGE_VERSION}
          """
        }
      }
    }

    stage('Check Version Not Exists') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'acr-push',
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          script {
            // 先登录，确保 manifest inspect 能访问私有仓库
            sh """
              set -e
              echo "\$ACR_PASS" | docker login ${REGISTRY} -u "\$ACR_USER" --password-stdin
            """

            // 检查 tag 是否存在
            def status = sh(
              script: "docker manifest inspect ${env.IMAGE_VERSION} > /dev/null 2>&1",
              returnStatus: true
            )

            if (status == 0) {
              error "版本 ${env.VERSION} 已存在（${env.IMAGE_VERSION}），禁止覆盖发布"
            }

            echo "OK：版本 ${env.VERSION} 不存在，可以发布"
          }
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

            echo "Pushing commit tag..."
            docker push ${env.IMAGE_COMMIT}

            echo "Pushing version tag..."
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
