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
            // Step 1: Get all EBS volumes that do not have a 'BackupFrequency' tag
            sh '''
                echo "🔍 Retrieving EBS volumes without required tags in region ${AWS_REGION}..."

                aws ec2 describe-volumes \
                    --region ${AWS_REGION} \
                    --query "Volumes[?!(Tags && Tags[?Key=='BackupFrequency'])].{ID:VolumeId}" \
                    --output json > untagged_volumes.json

                echo "📄 Untagged Volumes Found:"
                cat untagged_volumes.json
            '''

            // Step 2: Check if any untagged volumes were found
            def untaggedVolumes = readJSON file: 'untagged_volumes.json'
            if (untaggedVolumes.size() == 0) {
                echo "✅ No untagged volumes found. Skipping Lambda invocation."
            } else {
                echo "⚡ Invoking Lambda for untagged volumes..."
                writeJSON file: 'lambda_payload.json', json: [volumes: untaggedVolumes]

                sh '''
                    aws lambda invoke \
                      --function-name ${LAMBDA_FUNCTION_NAME} \
                      --region ${AWS_REGION} \
                      --payload file://lambda_payload.json \
                      lambda_output.json

                    echo "Lambda invoked successfully. Response:"
                    cat lambda_output.json
                '''
            }
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