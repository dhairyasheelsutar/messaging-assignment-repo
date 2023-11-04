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
                scripts {
                    sh 'aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin 986773572400.dkr.ecr.${REGION}.amazonaws.com'
                }
            }
        }
        
        stage("Build & Image") {
            steps {
                scripts {
                    sh 'cd app && docker build -t ecr-registry .'
                    sh 'docker tag ecr-registry:latest 986773572400.dkr.ecr.${REGION}.amazonaws.com/ecr-registry:latest'
                    sh 'docker push 986773572400.dkr.ecr.${REGION}.amazonaws.com/ecr-registry:latest'
                }
            }
        }

        stage("Deploy Application") {
            steps {
                echo "This is Stage 4"
            }
        }
    }
}
