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
        sh '''
            echo "🔍 Checking for untagged EBS volumes in region ${AWS_REGION}..."

            aws ec2 describe-volumes \
                --region ${AWS_REGION} \
                --query "Volumes[?!(Tags && Tags[?Key=='BackupFrequency'])].{ID:VolumeId}" \
                --output json > untagged_volumes.json

            COUNT=$(jq '. | length' untagged_volumes.json)
            echo "Found $COUNT untagged volumes."

            if [ "$COUNT" -eq 0 ]; then
                echo "✅ No untagged volumes found. Skipping Lambda."
                exit 0
            fi

            echo "⚡ Invoking Lambda with untagged volume list..."
            jq -n --argfile volumes untagged_volumes.json '{volumes: $volumes}' > lambda_payload.json

            aws lambda invoke \
              --function-name ${LAMBDA_FUNCTION_NAME} \
              --region ${AWS_REGION} \
              --payload file://lambda_payload.json \
              lambda_output.json

            echo "Lambda invocation result:"
            cat lambda_output.json
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
        booleanParam(
            name: 'TRIGGER_LAMBDA',
            defaultValue: false,
            description: 'Trigger the EBS compliance Lambda after apply?'
        )
    }   
}