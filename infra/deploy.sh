#!/bin/bash

# Deployment script for CI/CD Health Dashboard on AWS
# This script deploys the application using Terraform and Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    if ! command -v ssh &> /dev/null; then
        print_error "SSH is not installed. Please install SSH first."
        exit 1
    fi
    
    print_status "All prerequisites are installed."
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_status "Terraform initialized successfully."
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan
    print_status "Terraform plan completed."
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    terraform apply -auto-approve
    print_status "Terraform deployment completed."
}

# Get deployment outputs
get_outputs() {
    print_status "Getting deployment outputs..."
    
    INSTANCE_IP=$(terraform output -raw instance_public_ip)
    APP_URL=$(terraform output -raw application_url)
    API_URL=$(terraform output -raw api_url)
    
    print_status "Instance IP: $INSTANCE_IP"
    print_status "Application URL: $APP_URL"
    print_status "API URL: $API_URL"
}

# Deploy application code
deploy_application() {
    print_status "Deploying application code..."
    
    # Wait for instance to be ready
    print_status "Waiting for EC2 instance to be ready..."
    sleep 30
    
    # The application files are already cloned by user_data.sh
    # We just need to update the environment variables
    print_status "Application files are already cloned by user_data.sh..."
    
    # Update environment variables with RDS endpoint
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP "cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard && echo 'DATABASE_URL=postgres://postgres:password@$RDS_ENDPOINT:5432/cicd' > .env"
    
    # Start the application
    print_status "Starting the application..."
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP "cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard && docker-compose up -d --build"
    
    print_status "Application deployment completed."
}

# Wait for application to be ready
wait_for_application() {
    print_status "Waiting for application to be ready..."
    
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$APP_URL" > /dev/null 2>&1; then
            print_status "Application is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - Application not ready yet, waiting..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    print_warning "Application may not be fully ready. Please check manually."
}

# Display final information
display_final_info() {
    print_status "Deployment completed!"
    echo ""
    echo "=========================================="
    echo "CI/CD Health Dashboard Deployment Summary"
    echo "=========================================="
    echo "Instance IP: $INSTANCE_IP"
    echo "Application URL: $APP_URL"
    echo "API URL: $API_URL"
    echo "SSH Command: ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP"
    echo ""
    echo "To check application status:"
    echo "ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP 'cd /home/ec2-user/cicd-health-dashboard/CI-CD\\ Health\\ Dashboard && docker-compose ps'"
    echo ""
    echo "To view application logs:"
    echo "ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP 'cd /home/ec2-user/cicd-health-dashboard/CI-CD\\ Health\\ Dashboard && docker-compose logs -f'"
    echo ""
    print_status "Deployment completed successfully!"
}

# Main deployment function
main() {
    print_status "Starting CI/CD Health Dashboard deployment to AWS..."
    
    check_prerequisites
    init_terraform
    plan_terraform
    apply_terraform
    get_outputs
    deploy_application
    wait_for_application
    display_final_info
}

# Run main function
main "$@"
