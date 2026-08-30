pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci --ignore-scripts'
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test -- --runInBand'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker compose build app'
            }
        }
        stage('Prepare Environment') {
            steps {
                withCredentials([file(credentialsId: 'app-env-file', variable: 'ENV_FILE')]) {
                    sh 'cp "$ENV_FILE" .env'
                }
            }
        }

                        stage('Package Image') {
            steps {
                sh 'docker save nestjs-ddd-devops-app:latest -o app-image.tar'
            }
        }

        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh '''
                        scp -o StrictHostKeyChecking=no -i $SSH_KEY app-image.tar docker-compose.yml .env $SSH_USER@34.207.60.248:/home/ubuntu/devops-project1/
                        ssh -o StrictHostKeyChecking=no -i $SSH_KEY $SSH_USER@34.207.60.248 "cd /home/ubuntu/devops-project1 && docker load -i app-image.tar && docker compose up -d && rm app-image.tar"
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 10
                    curl -f http://34.207.60.248:3000/api/v1/health
                '''
            }
        }
     }
    post {
        success {
            echo 'CI/CD Pipeline completed successfully!'
        }

        failure {
            echo 'CI/CD Pipeline failed!'
        }
    }
}

