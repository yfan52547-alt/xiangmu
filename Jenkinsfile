pipeline {
  agent any

  environment {
    // ACR Registry（不要带 https://）
    REGISTRY   = "crpi-qvxmqo14dnp2pn9g.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE  = "ray-dev"
    IMAGE_NAME = "gallery-app"
  }

  stages {
    stage('Git Setup') {
      steps {
        // 配置 Git 使用 HTTP/1.1，增加缓存和超时设置
        sh '''
          git config --global http.postBuffer 524288000
          git config --global core.compression 9
          git config --global pack.threads 1
          git config --global http.version HTTP/1.1
          git config --global http.lowSpeedLimit 0
          git config --global http.lowSpeedTime 99999
        '''
      }
    }

    stage('Checkout') {
      steps {
        // 拉取代码时加入重试机制，最多重试3次
        script {
          retry(3) {
            checkout scm
          }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          // 获取当前提交的 Git 提交哈希（short SHA）
          def sha = sh(
            script: "git rev-parse --short HEAD",
            returnStdout: true
          ).trim()
          // 构建镜像的标签（dev-版本号-提交哈希）
          env.IMAGE_TAG = "commit-${sha}"
          env.IMAGE = "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.IMAGE_TAG}"
          // 使用 Docker 构建镜像
          sh """
            set -e
            docker build -t ${env.IMAGE} .
          """
        }
      }
    }

    stage('Push to ACR DEV (auto)') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'acr-login',  // 修改为已有的凭据ID
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          sh """
            set -ex
            echo "\$ACR_PASS" | docker login ${REGISTRY} -u "\$ACR_USER" --password-stdin
            docker push ${env.IMAGE}
            echo "${env.IMAGE}" > build-info.txt
          """
        }

        archiveArtifacts artifacts: 'build-info.txt', fingerprint: true
      }
    }

    stage('Deploy (optional local run)') {
      steps {
        script {
          // 使用 commit-${sha} 标签
          def localImage = "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.IMAGE_TAG}"
          sh """
            set -e
            docker rm -f demo-web || true
            docker run -d --name demo-web -p 8088:80 ${localImage}
            echo "Deployed locally: http://<your-ecs-ip>:8088"
          """
        }
      }
    }

    stage('Promote to ACR TEST (manual approval + version V.1.X)') {
      steps {
        script {
          // 让用户输入版本号和 Docker 用户名
          def userInput = input(
            message: '确认要推送到 TEST 仓库吗？请输入版本号和 Docker 用户名',
            ok: '确认推送',
            parameters: [
              string(name: 'VERSION', defaultValue: 'V.1.1', description: '请输入版本号，例如 V.1.2'),
              string(name: 'DOCKER_USERNAME', defaultValue: 'fanyibo-20251013', description: '请输入 Docker 用户名')
            ]
          )

          def version = userInput['VERSION']
          def dockerUsername = userInput['DOCKER_USERNAME']

          // 校验版本号格式：只允许类似 xiangmu.1.1 格式
          if (!(version ==~ /^[a-zA-Z]{1,8}\.\d+\.\d+$/)) {
            error("版本号格式不正确：${version}，必须是类似 xiangmu.1.1 的格式")
          }

          // 确定要推送到 ACR TEST 的镜像地址
          def TEST_IMAGE = "${REGISTRY}/${NAMESPACE}/gallery-app:${version}"

          // 使用输入的 Docker 用户名进行 Docker 登录
          withCredentials([usernamePassword(credentialsId: 'acr-login', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
            sh """
              set -e
              echo "\$ACR_PASS" | docker login ${REGISTRY} -u "${dockerUsername}" --password-stdin
              docker tag ${env.IMAGE} ${TEST_IMAGE}
              docker push ${TEST_IMAGE}
              echo "Pushed TEST: ${TEST_IMAGE}"
            """
          }
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline finished."
    }
  }
}
