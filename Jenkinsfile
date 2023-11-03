pipeline {
    agent any

    stages {
        stage("Running Tests") {
            steps {
                echo "Run tests here"
            }
        }
        
        stage("Build Image") {
            steps {
                ls -alh
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
