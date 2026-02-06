pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  parameters {
    booleanParam(name: 'LOCAL_DEPLOY', defaultValue: false, description: '是否在 Jenkins 节点上本地 docker run')
    string(name: 'RELEASE_VERSION', defaultValue: '', description: '发布到 TEST 的版本号（可选）')
  }

  environment {
    REGISTRY   = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
    NAMESPACE  = "rad-dev"
    REPO       = "gallery-test"
  }

  stages {
    stage('Sanity') {
      steps {
        echo "Jenkinsfile is running!"
        sh 'pwd'
        sh 'ls -la'
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }
  }
}
