pipeline {
    agent any

    environment {
        REGION = 'us-east-1'
    }

    stages {
        stage("Running Tests") {
            steps {
                echo "Run tests here"
            }
        }

        stage("Authenticate with ECR") {
            steps {
                script {
                    sh 'aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin 986773572400.dkr.ecr.${REGION}.amazonaws.com'
                }
            }
        }
        
        stage("Build & Image") {
            steps {
                script {
                    sh 'Commit ID: ${env.GIT_COMMIT}'
                    sh 'cd app && docker build -t ecr-registry .'
                    sh 'docker tag ecr-registry:latest 986773572400.dkr.ecr.${REGION}.amazonaws.com/ecr-registry:latest'
                    sh 'docker push 986773572400.dkr.ecr.${REGION}.amazonaws.com/ecr-registry:latest'
                }
            }
        }

        stage("Deploy Application") {
            steps {
                script {
                    sh 'cd IaC/app'
                    sh 'terraform init'
                    sh 'terraform plan'
                }
            }
        }
    }
}
