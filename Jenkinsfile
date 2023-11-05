pipeline {
    agent any

    environment {
        REGION = 'us-east-1'
        ACCOUNT = '986773572400'
        CLUSTER_NAME = 'eks-cluster'
    }

    stages {
        
        stage("Authenticate with ECR") {
            steps {
                script {
                    sh 'aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin 986773572400.dkr.ecr.${REGION}.amazonaws.com'
                }
            }
        }
        
        stage("Build & Push Image") {
            steps {
                script {
                    sh 'cd app && docker build -t ecr-registry .'
                    sh 'docker tag ecr-registry:latest ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/ecr-registry:${GIT_COMMIT}'
                    sh 'docker push ${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/ecr-registry:${GIT_COMMIT}'
                }
            }
        }

        stage("Deploy Application") {
            steps {
                script {
                    sh 'aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}'
                    sh '''
                        sed "s|\\\${image}|${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/ecr-registry:${GIT_COMMIT}|" k8s/deployment.yaml > deploy.yaml
                    '''
                    sh 'ls'
                    sh '/usr/local/bin/kubectl apply -f deploy.yaml'
                }
            }
        }
    }
}