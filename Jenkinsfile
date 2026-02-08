node {

  env.REGISTRY  = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
  env.NAMESPACE = "rad-dev"
  env.REPO      = "gallery-test"

  stage('CHECK') {
    echo 'CHECK START'
    sh '''
      set -eux
      whoami
      pwd
      ls -la
      docker version || true
    '''
  }

  stage('CHECKOUT') {
    checkout([
      $class: 'GitSCM',
      branches: [[name: '*/main']],
      userRemoteConfigs: [[
        url: 'https://github.com/yfan52547-alt/xiangmu.git',
        credentialsId: 'github-token'
      ]]
    ])
    sh 'git log -1 --oneline'
  }

  stage('BUILD') {
    sh '''
      set -eux
      if [ ! -f Dockerfile ]; then
        echo "ERROR: Dockerfile not found"
        exit 1
      fi

      TAG=$(git rev-parse --short HEAD)
      IMAGE=$REGISTRY/$NAMESPACE/$REPO:commit-$TAG
      echo "IMAGE=$IMAGE"

      docker build -t "$IMAGE" .
      echo "$IMAGE" > image.txt
    '''
  }

  stage('LOGIN & PUSH') {
    withCredentials([usernamePassword(
      credentialsId: 'acr-push',
      usernameVariable: 'ACR_USER',
      passwordVariable: 'ACR_PASS'
    )]) {
      sh '''
        set -eux
        IMAGE=$(cat image.txt)
        echo "$ACR_PASS" | docker login "$REGISTRY" -u "$ACR_USER" --password-stdin
        docker push "$IMAGE"
      '''
    }
  }

}
