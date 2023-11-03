pipeline {
    agent any

    stages {
        stage("Running Tests") {
            steps {
                echo "Run tests here"
            }
        }

        stage("Authenticate with ECR") {
            steps {
                echo "Authenticate with ECR"
            }
        }
        
        stage("Build Image") {
            steps {
                sh "cd app && docker build -t webservice ."
            }
        }

        stage("Push Image") {
            steps {
                echo "This is Stage 3"
            }
        }

        stage("Deploy Application") {
            steps {
                echo "This is Stage 4"
            }
        }
    }
}
