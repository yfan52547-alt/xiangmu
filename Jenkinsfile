pipeline {
  agent any

  environment {
    ACR_REGISTRY  = "crpi-qvxmqo14dnp2pn9g.cn-hangzhou.personal.cr.aliyuncs.com"
    ACR_NAMESPACE = "ray-dev"

    DEV_REPO  = "gallery-app"
    TEST_REPO = "ray-dev"

    IMAGE_LOCAL = "demo-web:latest"
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
            echo "${ACR_PASS}" | docker login -u "${ACR_USER}" --password-stdin ${ACR_REGISTRY}

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
          def version = input(
            message: '确认要推送到 TEST 仓库吗？请输入版本号（格式：V.1.X，例如 V.1.2）',
            ok: '确认推送',
            parameters: [
              string(name: 'VERSION', defaultValue: 'V.1.1', description: '必须是 V.1.X')
            ]
          ) as String

          if (!(version ==~ /V\\.1\\.\\d+/)) {
            error("版本号格式不正确：${version}，必须是 V.1.X（例如 V.1.2）")
          }

          def testImage = "${env.ACR_REGISTRY}/${env.ACR_NAMESPACE}/${env.TEST_REPO}:${version}"

          withCredentials([usernamePassword(credentialsId: 'acr-login', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
            sh """
              set -e
              echo "\$ACR_PASS" | docker login -u "\$ACR_USER" --password-stdin ${env.ACR_REGISTRY}
              docker tag ${env.IMAGE_LOCAL} ${testImage}
              docker push ${testImage}
              echo "Pushed TEST: ${testImage}"
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
