pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        TF_CLI_ARGS            = "-no-color"
    }

    stages {
        stage('Terraform Init & Plan') {
            steps {
                sh '''
                  cd terraform
                  terraform init
                  terraform plan -out=tfplan
                '''
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return params.APPLY == true }
            }
            steps {
                sh '''
                  cd terraform
                  terraform apply --auto-approve tfplan
                '''
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return params.DESTROY == true }
            }
            steps {
                sh '''
                  cd terraform
                  terraform destroy --auto-approve
                '''
            }
        }
    }

    parameters {
        booleanParam(name: 'APPLY', defaultValue: true, description: 'Apply Terraform changes')
        booleanParam(name: 'DESTROY', defaultValue: false, description: 'Destroy Terraform-managed resources')
    }
}