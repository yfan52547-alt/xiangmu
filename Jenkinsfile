pipeline {
  agent any

  environment {
    // ACR Registry（不要带 https://）
    ACR_REGISTRY = "crpi-qvxmqo14dnp2pn9g.cn-hangzhou.personal.cr.aliyuncs.com"

    // 命名空间 namespace
    ACR_NAMESPACE = "ray-dev"

    // 你选的 B：dev=gallery-app, test=ray-dev
    DEV_REPO  = "gallery-app"
    TEST_REPO = "ray-dev"

    // 本地镜像名
    IMAGE_LOCAL = "demo-web:latest"

    // 运行容器名 / 端口
    APP_NAME = "demo-web"
    WEB_PORT = "8088"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        sh 'ls -la'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          set -e
          docker version
          docker build -t ${IMAGE_LOCAL} .
        '''
      }
    }

    stage('Push to ACR DEV (auto)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'acr-login', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
          sh '''
            set -e

            # 登录 ACR（密码走 Jenkins 凭据，不需要你手输）
            echo "${ACR_PASS}" | docker login -u "${ACR_USER}" --password-stdin ${ACR_REGISTRY}

            # dev 镜像打 tag：用构建号 + 短 commit（方便追溯）
            GIT_SHA=$(git rev-parse --short HEAD)
            DEV_TAG="dev-${BUILD_NUMBER}-${GIT_SHA}"

            DEV_IMAGE="${ACR_REGISTRY}/${ACR_NAMESPACE}/${DEV_REPO}:${DEV_TAG}"
            DEV_LATEST="${ACR_REGISTRY}/${ACR_NAMESPACE}/${DEV_REPO}:latest"

            docker tag ${IMAGE_LOCAL} ${DEV_IMAGE}
            docker tag ${IMAGE_LOCAL} ${DEV_LATEST}

            docker push ${DEV_IMAGE}
            docker push ${DEV_LATEST}

            echo "Pushed DEV: ${DEV_IMAGE}"
          '''
        }
      }
    }

    stage('Deploy (optional local run)') {
      steps {
        sh '''
          set -e
          docker rm -f ${APP_NAME} || true
          docker run -d --name ${APP_NAME} -p ${WEB_PORT}:80 ${IMAGE_LOCAL}
          echo "Deployed locally: http://<your-ecs-ip>:${WEB_PORT}"
        '''
      }
    }

    stage('Promote to ACR TEST (manual approval + version V.1.X)') {
  steps {
    script {
      // 1) 人工确认 + 手动输入版本号
      def version = input(
        message: '确认要推送到 TEST 仓库吗？请输入版本号（格式：V.1.X，例如 V.1.2）',
        ok: '确认推送',
        parameters: [
          string(name: 'VERSION', defaultValue: 'V.1.1', description: '必须是 V.1.X')
        ]
      ) as String

      // 2) 版本格式校验：只允许 V.1.X
      if (!(version ==~ /V\.1\.\d+/)) {
        error("版本号格式不正确：${version}，必须是 V.1.X（例如 V.1.2）")
      }

      // 3) 目标 TEST 镜像地址（你确认的 ray-dev/ray-dev）
      def TEST_IMAGE = "crpi-qvxmqo14dnp2pn9g.cn-hangzhou.personal.cr.aliyuncs.com/ray-dev/ray-dev:${version}"

      // 4) 登录 + tag + push
      sh """
        set -e
        echo "\$ACR_PASS" | docker login -u "\$ACR_USER" --password-stdin crpi-qvxmqo14dnp2pn9g.cn-hangzhou.personal.cr.aliyuncs.com
        docker tag demo-web:latest ${TEST_IMAGE}
        docker push ${TEST_IMAGE}
        echo "Pushed TEST: ${TEST_IMAGE}"
      """
    }
  }
}


        withCredentials([usernamePassword(credentialsId: 'acr-login', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
          sh '''
            set -e

            echo "${ACR_PASS}" | docker login -u "${ACR_USER}" --password-stdin ${ACR_REGISTRY}

            TEST_IMAGE="${ACR_REGISTRY}/${ACR_NAMESPACE}/${TEST_REPO}:${RELEASE_VERSION}"
            docker tag ${IMAGE_LOCAL} ${TEST_IMAGE}
            docker push ${TEST_IMAGE}

            echo "Pushed TEST: ${TEST_IMAGE}"
          '''
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
