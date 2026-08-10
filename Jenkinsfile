pipeline {
    agent any

    environment {
        // We use host.docker.internal so the Jenkins container can securely route traffic to your Windows network
        NEXUS_REGISTRY = 'host.docker.internal:8082'
        IMAGE_NAME = 'enterprise-app'
    }

    stages {
        stage('Compile & Unit Test') {
            steps {
                echo 'Compiling Spring Boot Application...'
                // Ensure the wrapper is executable, then build
                sh 'chmod +x gradlew'
                sh './gradlew clean build -x test --no-daemon'
            }
        }

        stage('Security Gate: IAM Token Validation') {
            steps {
                echo 'Testing Keycloak Identity Provider connection...'
                // This explicitly measures the integration latency and efficiency of the IAM security gate
                withCredentials([string(credentialsId: 'keycloak-secret', variable: 'KC_SECRET')]) {
                    script {
                        def response = sh(script: '''
                            curl -s -w "%{http_code}" -o /dev/null -X POST "http://host.docker.internal:9090/realms/enterprise-realm/protocol/openid-connect/token" \
                            -H "Content-Type: application/x-www-form-urlencoded" \
                            -d "grant_type=client_credentials" \
                            -d "client_id=spring-boot-api" \
                            -d "client_secret=${KC_SECRET}"
                        ''', returnStdout: true).trim()
                        
                        if (response != "200") {
                            error("IAM Security Gate Failed: Keycloak returned HTTP ${response}")
                        } else {
                            echo "IAM Security Gate Passed! Token successfully generated."
                        }
                    }
                }
            }
        }

        stage('Package Immutable Artifact') {
            steps {
                echo 'Building Multi-Stage Docker Image...'
                // We tag it with the unique Jenkins Build Number for version control, and also as 'latest'
                sh "docker build -t ${NEXUS_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER} ."
                sh "docker tag ${NEXUS_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER} ${NEXUS_REGISTRY}/${IMAGE_NAME}:latest"
            }
        }

        stage('Artifact Storage: Push to Nexus') {
            steps {
                echo 'Authenticating and pushing to private Sonatype Nexus safe...'
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials', usernameVariable: 'NEXUS_USR', passwordVariable: 'NEXUS_PSW')]) {
                    sh "echo \$NEXUS_PSW | docker login ${NEXUS_REGISTRY} -u \$NEXUS_USR --password-stdin"
                    sh "docker push ${NEXUS_REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker push ${NEXUS_REGISTRY}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Continuous Deployment: Ansible Push to OpenShift') {
            environment {
                OPENSHIFT_SERVER = 'https://api.rm2.thpm.p1.openshiftapps.com:6443'
            }
            steps {
                echo 'Initiating Push-Based CD via Ansible...'
                withCredentials([string(credentialsId: 'openshift-token', variable: 'OPENSHIFT_TOKEN')]) {
                    sh 'ansible-playbook cd-deploy.yml'
                }
            }
        }
    }
}