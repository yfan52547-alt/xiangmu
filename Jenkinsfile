pipeline {
  agent any
stage('Sanity') {
  steps {
    echo "Jenkinsfile is running!"
    sh 'ls -la'
  }
}

  options {
    timestamps()
    disableConcurrentBuilds()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  parameters {
    booleanParam(name: 'LOCAL_DEPLOY', defaultValue: false, description: '是否在 Jenkins 节点上本地 docker run（仅当该节点就是你的 ECS/宿主机时打开）')
    string(name: 'RELEASE_VERSION', defaultValue: '', description: '发布到 TEST 的版本号（可选）。格式示例：xiangmu.1.1；留空则不发布到 TEST')
  }

  environment {
    // 新 ACR（不要带 https://）
    REGISTRY   = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE  = "rad-dev"
    REPO       = "gallery-test"

    // 你原来本地跑是 8088:80，这里保留
    LOCAL_PORT = "8088"
    CONTAINER  = "demo-web"
  }

  stages {

    stage('Precheck') {
      steps {
        sh '''
          set -e
          echo "=== Precheck ==="
          echo "REGISTRY:  ${REGISTRY}"
          echo "IMAGE:     ${REGISTRY}/${NAMESPACE}/${REPO}"
          command -v docker >/dev/null 2>&1 || (echo "Docker not found on agent!" && exit 1)
          docker version >/dev/null 2>&1 || (echo "Docker daemon not reachable!" && exit 1)
        '''
      }
    }

    stage('Checkout') {
      steps {
        script {
          retry(3) { checkout scm }
        }
      }
    }

    stage('Compute Tags') {
      steps {
        script {
          def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          env.COMMIT_TAG = "commit-${sha}"
          env.IMAGE_COMMIT = "${REGISTRY}/${NAMESPACE}/${REPO}:${env.COMMIT_TAG}"

          echo "Commit tag: ${env.COMMIT_TAG}"
          echo "Image: ${env.IMAGE_COMMIT}"
        }
      }
    }

    stage('Build Image') {
      steps {
        sh '''
          set -e
          echo "=== Build ==="
          docker build -t ${IMAGE_COMMIT} .
          docker images | head -n 5
        '''
      }
    }

    stage('Login & Push (DEV)') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'acr-login',
          usernameVariable: 'ACR_USER',
          passwordVariable: 'ACR_PASS'
        )]) {
          sh '''
            set -e
            echo "=== Login & Push DEV ==="
            echo "$ACR_PASS" | docker login ${REGISTRY} -u "$ACR_USER" --password-stdin
            docker push ${IMAGE_COMMIT}
            echo "${IMAGE_COMMIT}" > build-info.txt
          '''
        }
        archiveArtifacts artifacts: 'build-info.txt', fingerprint: true
      }
    }

    stage('Local Deploy (optional)') {
      when { expression { return params.LOCAL_DEPLOY } }
      steps {
        sh '''
          set -e
          echo "=== Local Deploy ==="
          docker rm -f ${CONTAINER} >/dev/null 2>&1 || true
          docker run -d --name ${CONTAINER} -p ${LOCAL_PORT}:80 ${IMAGE_COMMIT}
          echo "Local deployed: http://<agent-ip>:${LOCAL_PORT}"
        '''
      }
    }

    stage('Promote to TEST (manual gate)') {
      when {
        expression { return params.RELEASE_VERSION?.trim() }
      }
      steps {
        script {
          // 手动确认
          input message: "确认要发布到 TEST 吗？将推送版本：${params.RELEASE_VERSION}", ok: '确认发布'

          def version = params.RELEASE_VERSION.trim()

          // 校验：类似 xiangmu.1.1
          if (!(version ==~ /^[a-zA-Z]{1,8}\\.[0-9]+\\.[0-9]+$/)) {
            error("版本号格式不正确：${version}，必须类似 xiangmu.1.1")
          }

          env.IMAGE_TEST = "${REGISTRY}/${NAMESPACE}/${REPO}:${version}"
          echo "TEST Image: ${env.IMAGE_TEST}"

          withCredentials([usernamePassword(credentialsId: 'acr-login', usernameVariable: 'ACR_USER', passwordVariable: 'ACR_PASS')]) {
            sh '''
              set -e
              echo "=== Promote TEST ==="
              echo "$ACR_PASS" | docker login ${REGISTRY} -u "$ACR_USER" --password-stdin
              docker tag ${IMAGE_COMMIT} ${IMAGE_TEST}
              docker push ${IMAGE_TEST}
            '''
          }
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline finished."
      sh 'docker logout ${REGISTRY} >/dev/null 2>&1 || true'
    }
  }
}
