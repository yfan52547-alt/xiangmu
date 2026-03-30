pipeline {
    agent any

    environment {
        // ACR 信息
        REGISTRY   = "crpi-2nt3d5r15x1zymbh.cn-hangzhou.personal.cr.aliyuncs.com"
        NAMESPACE  = "rad-dev"
        IMAGE_NAME = "gallery-test"
    }

    stages {

        stage('Git Setup') {
            steps {
                // Git 优化配置，国内网络稳定性
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
                script {
                    // 拉取代码，最多重试3次
                    retry(3) {
                        checkout scm
                    }
                }
            }
        }

        stage('Build Image') {
            steps {
                script {
                    // commit short SHA
                    def sha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.COMMIT_TAG   = "commit-${sha}"
                    env.IMAGE_COMMIT = "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.COMMIT_TAG}"

                    // 构建 DEV 镜像
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
                    // 人工输入正式版本号
                    def userInput = input(
                        message: "请输入版本号（允许：V1.2 或 V1.2.3）\\n确认后将推送：版本 + commit + latest",
                        ok: "确认发布",
                        parameters: [
                            string(name: 'VERSION', defaultValue: 'V1.0', description: '格式：V数字.数字 或 V数字.数字.数字')
                        ]
                    )

                    def v = userInput.trim()
                    // 转半角点/数字
                    v = v.replace('。', '.').replace('．', '.').replace('·', '.')
                    v = v.collect { ch ->
                        int code = (int) ch.charAt(0)
                        if (code >= 65296 && code <= 65305) return (char)(code - 65248)
                        return ch
                    }.join('')

                    // 校验版本号
                    def pattern = /^V\d+\.\d+(\.\d+)?$/
                    if (!(v ==~ pattern)) {
                        error "版本号格式错误：${v}，允许格式：V1.2 或 V1.2.3（必须大写V）"
                    }

                    env.VERSION       = v
                    env.IMAGE_VERSION = "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${env.VERSION}"
                    env.IMAGE_LATEST  = "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:latest"

                    sh """
                        set -e
                        echo "Tagging => ${env.IMAGE_COMMIT} -> ${env.IMAGE_VERSION}"
                        docker tag ${env.IMAGE_COMMIT} ${env.IMAGE_VERSION}

                        echo "Tagging => ${env.IMAGE_VERSION} -> ${env.IMAGE_LATEST}"
                        docker tag ${env.IMAGE_VERSION} ${env.IMAGE_LATEST}
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
                        sh """
                            set -e
                            echo "\$ACR_PASS" | docker login ${REGISTRY} -u "\$ACR_USER" --password-stdin
                        """
                        def status = sh(
                            script: "docker manifest inspect ${env.IMAGE_VERSION} > /dev/null 2>&1",
                            returnStatus: true
                        )
                        if (status == 0) {
                            error "版本 ${env.VERSION} 已存在（${env.IMAGE_VERSION}），禁止覆盖发布"
                        }
                        echo "OK：版本 ${env.VERSION} 不存在，可以发布（latest 将被更新）"
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

                        echo "Pushing commit tag => ${env.IMAGE_COMMIT}"
                        docker push ${env.IMAGE_COMMIT}

                        echo "Pushing version tag => ${env.IMAGE_VERSION}"
                        docker push ${env.IMAGE_VERSION}

                        echo "Pushing latest tag => ${env.IMAGE_LATEST}"
                        docker push ${env.IMAGE_LATEST}

                        echo "${env.IMAGE_VERSION}" > build-info.txt
                    """
                }

                archiveArtifacts artifacts: 'build-info.txt', fingerprint: true
                echo "✅ DEV/Release image pushed successfully"
            }
        }

        stage('Optional Local Run') {
            when {
                expression { return true } // 如果想测试 DEV 镜像，可改条件
            }
            steps {
                script {
                    sh """
                        docker rm -f ${IMAGE_NAME}-test || true
                        docker run -d --name ${IMAGE_NAME}-test -p 8088:80 ${env.IMAGE_COMMIT}
                        echo "Local DEV container running at http://<ecs-ip>:8088"
                    """
                }
            }
        }

        stage('Deploy to TEST (optional)') {
            when {
                expression { return true } // 企业环境可打开部署到 TEST
            }
            steps {
                script {
                    if (env.IMAGE_VERSION.startsWith("V")) {
                        sh """
                            docker pull ${env.IMAGE_VERSION} && docker run -d --name ${IMAGE_NAME}-test -p 8089:80 ${env.IMAGE_VERSION}
                        """
                        echo "Deployed TEST image: ${env.IMAGE_VERSION}"
                    } else {
                        error "TEST 部署只允许 release 镜像"
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
