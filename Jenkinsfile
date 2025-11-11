pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        TF_CLI_ARGS            = "-no-color"
        LAMBDA_FUNCTION_NAME  = 'EBSBackupFrequencyChecker'
        AWS_REGION            = "us-east-1"
        ACCOUNT_ID            = "636361317523"
    }

    stages {
        stage('Validate Parameters') {
            steps {
                script {
                    if (params.TRIGGER_LAMBDA && params.ACTION != 'apply') {
                        error("❌ Invalid selection: TRIGGER_LAMBDA can only be true when ACTION=apply.")
                    }
                }
            }
        }

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

        stage('Trigger Lambda') {
            when {
                allOf {
                    expression { return params.ACTION == 'apply' }
                    expression { return params.TRIGGER_LAMBDA == true }
                }
            }
            steps {
                script {
                    // Escape backticks for Groovy and shell
                    def volumes = sh(script: """
                        aws ec2 describe-volumes --query 'Volumes[?Tags[?Key==\`backup_frequency\`]==null].VolumeId' --output json
                    """, returnStdout: true).trim()

                    // Check if volumes are empty
                    if (volumes == "[]") {
                        echo "No volumes missing the 'backup_frequency' tag."
                        return
                    }

                    // Format the volumes as ARNs and build the payload
                    def volumeArns = sh(script: """
                        echo '$volumes' | jq -r '.[] | \"arn:aws:ec2:${REGION}:${ACCOUNT_ID}:volume/\(.VolumeId)\"'
                    """, returnStdout: true).trim()

                    // Build the final payload
                    def payload = """{"resources": [${volumeArns}]}"""
                    
                    // Print the payload to verify
                    echo "Generated payload: ${payload}"

                    // Invoke the Lambda function
                    sh(script: """
                        aws lambda invoke \
                            --function-name your-lambda-function-name \
                            --payload '${payload}' \
                            output.txt
                    """)

                    // Print the output from the invocation
                    def output = readFile('output.txt')
                    echo "Lambda output: ${output}"
                }
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
        booleanParam(
            name: 'TRIGGER_LAMBDA',
            defaultValue: false,
            description: 'Trigger the EBS compliance Lambda after apply?'
        )
    }   
}