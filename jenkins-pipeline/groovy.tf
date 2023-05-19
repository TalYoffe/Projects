pipeline {
    agent any
    
    triggers {
        pollSCM('*/5 * * * *') // SCM polling trigger every 5 minutes
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                git 'https://github.com/your-username/your-repo.git' // Clone the repository containing Terraform files
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh 'terraform init' // Initialize Terraform in the repository directory
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan' // Run Terraform plan
            }
        }
        
        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    def userInput = input(
                        id: 'userInput',
                        message: 'Choose an action:',
                        parameters: [
                            choice(name: 'ACTION', choices: ['Apply', 'Destroy'], description: 'Select an action to perform')
                        ]
                    )
                    
                    if (userInput.ACTION == 'Apply') {
                        sh 'terraform apply -auto-approve tfplan' // Run Terraform apply with auto-approval
                    } else if (userInput.ACTION == 'Destroy') {
                        sh 'terraform destroy -auto-approve' // Run Terraform destroy with auto-approval
                    }
                }
            }
        }
    }
}
