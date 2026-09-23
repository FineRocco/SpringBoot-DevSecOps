pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        NEXUS_REGISTRY = 'host.docker.internal:8082'
        IMAGE_NAME = 'enterprise-app'
    }

    stages {
        stage('Compile & Unit Test') {
            steps {
                echo 'Compiling Spring Boot Application...'
                sh 'chmod +x mvnw'
                sh './mvnw clean package -DskipTests'
            }
        }

        stage('Security Gate: IAM Token Validation') {
            steps {
                echo 'Testing Keycloak Identity Provider connection...'
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

        stage('Continuous Deployment: Ansible Local Docker Deploy') {
            steps {
                echo 'Initiating Push-Based CD to Local Docker via Ansible...'
                sh 'ansible-playbook cd-deploy.yml'
            }
        }
    }
}