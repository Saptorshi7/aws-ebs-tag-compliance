pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        AWS_SESSION_TOKEN     = credentials('aws_session_token')
        TF_CLI_ARGS           = "-no-color"
        LAMBDA_FUNCTION_NAME  = 'EBSBackupFrequencyChecker'
        AWS_REGION            = "us-east-1"
        ACCOUNT_ID            = "361509912577"
        SNS_TOPIC_ARN         = "arn:aws:sns:us-east-1:361509912577:EBSMissingTagAlerts"
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
                  terraform init -reconfigure
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

        stage('Wait for SNS Subscription Confirmation') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    echo "⏳ Checking SNS subscriptions for topic: ${SNS_TOPIC_ARN}"

                    timeout(time: 5, unit: 'MINUTES') {
                        waitUntil {
                            def status = sh(
                                script: """
                                    aws sns list-subscriptions-by-topic \
                                      --topic-arn ${SNS_TOPIC_ARN} \
                                      --region ${AWS_REGION} \
                                      --query "Subscriptions[?SubscriptionArn!='PendingConfirmation'].SubscriptionArn" \
                                      --output text
                                """,
                                returnStdout: true
                            ).trim()

                            if (status) {
                                echo "✅ Subscription confirmed: ${status}"
                                return true
                            } else {
                                echo "⚠️ Subscription still pending confirmation. Please check your email and confirm."
                                sleep 20
                                return false
                            }
                        }
                    }
                }
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

            # Read the first few untagged volumes
            echo "⚡ Preparing payloads and invoking Lambda..."

            for VOL_ID in $(jq -r '.[].ID' untagged_volumes.json); do
                PAYLOAD=$(jq -nc --arg vol_arn "arn:aws:ec2:${AWS_REGION}:${ACCOUNT_ID}:volume/${VOL_ID}" '{resources: [$vol_arn]}')

                echo "Invoking Lambda for volume ${VOL_ID}..."
                echo "$PAYLOAD" > lambda_payload.json
                cat lambda_payload.json

                aws lambda invoke \
                  --function-name ${LAMBDA_FUNCTION_NAME} \
                  --region ${AWS_REGION} \
                  --payload file://lambda_payload.json \
                  lambda_output.json \
                  --cli-binary-format raw-in-base64-out

                echo "Lambda output for ${VOL_ID}:"
                cat lambda_output.json
                echo ""
            done
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