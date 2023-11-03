pipeline {
    agent any

    stages {
        stage("Running Tests") {
            steps {
                echo "This is Stage 1"
            }
        }
        
        stage("Build Image") {
            steps {
                echo "This is Stage 2"
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
