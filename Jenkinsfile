pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        TF_CLI_ARGS            = "-no-color"
    }

    stages {
        stage('Terraform Init') {
            steps {
                sh '''
                  terraform init
                '''
            }
        }

        stage('Terraform Plan') {
            when {
                expression { return params.ACTION == 'plan' || params.ACTION == 'apply' }
            }
            steps {
                sh '''
                  terraform plan -out=tfplan
                '''
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                sh '''
                  terraform apply --auto-approve tfplan
                '''
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return params.ACTION == 'destroy' }
            }
            steps {
                sh '''
                  terraform destroy --auto-approve
                '''
            }
        }
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Choose Terraform action to perform'
        )
    }   
}