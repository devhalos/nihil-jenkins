#!*groovy*

pipeline {
    agent {
        ecs {
            inheritFrom 'nihil-dev-jenkins-service'
            label 'nihil-dev-jenkins-service'
        }
    }

    stages {
        stage('init') {
            steps {
                echo 'hello world'
            }
        }
    }
}