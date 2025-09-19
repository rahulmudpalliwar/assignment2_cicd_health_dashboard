#!/bin/bash

# Quick start script for CI/CD Health Dashboard AWS deployment
# This script provides an interactive setup and deployment experience

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        missing_tools+=("AWS CLI")
    else
        print_status "AWS CLI found"
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("Terraform")
    else
        print_status "Terraform found"
    fi
    
    # Check SSH
    if ! command -v ssh &> /dev/null; then
        missing_tools+=("SSH")
    else
        print_status "SSH found"
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        missing_tools+=("Git")
    else
        print_status "Git found"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install the missing tools and run this script again."
        exit 1
    fi
}

# Check AWS configuration
check_aws_config() {
    print_header "Checking AWS Configuration"
    
    if aws sts get-caller-identity &> /dev/null; then
        print_status "AWS credentials configured"
        aws sts get-caller-identity --query 'Account' --output text | xargs -I {} print_status "AWS Account: {}"
    else
        print_error "AWS credentials not configured or invalid"
        print_status "Please run 'aws configure' to set up your credentials"
        exit 1
    fi
}

# Check SSH key
check_ssh_key() {
    print_header "Checking SSH Key"
    
    if [ -f ~/.ssh/id_rsa.pub ]; then
        print_status "SSH public key found at ~/.ssh/id_rsa.pub"
    else
        print_warning "SSH public key not found"
        read -p "Do you want to generate a new SSH key pair? (y/n): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
            print_status "SSH key pair generated"
        else
            print_error "SSH key is required for deployment"
            exit 1
        fi
    fi
}

# Configure Terraform variables
configure_terraform() {
    print_header "Configuring Terraform Variables"
    
    if [ ! -f "terraform.tfvars" ]; then
        print_status "Creating terraform.tfvars from template..."
        cp terraform.tfvars.example terraform.tfvars
    fi
    
    print_warning "Please review and update terraform.tfvars with your specific configuration:"
    echo ""
    cat terraform.tfvars
    echo ""
    read -p "Do you want to edit terraform.tfvars now? (y/n): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} terraform.tfvars
    fi
}

# Deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying Infrastructure"
    
    print_status "This will deploy the following AWS resources:"
    echo "  - VPC with public subnet"
    echo "  - EC2 instance (t2.micro)"
    echo "  - RDS PostgreSQL database (db.t3.micro)"
    echo "  - Security groups and networking"
    echo "  - Elastic IP for static access"
    echo ""
    print_warning "Estimated cost: $0 (Free Tier eligible resources)"
    echo ""
    
    read -p "Do you want to proceed with the deployment? (y/n): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled"
        exit 0
    fi
    
    # Run deployment
    print_status "Starting deployment..."
    ./deploy.sh
}

# Show final information
show_final_info() {
    print_header "Deployment Complete!"
    
    if [ -f "terraform.tfstate" ]; then
        INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "Not available")
        APP_URL=$(terraform output -raw application_url 2>/dev/null || echo "Not available")
        API_URL=$(terraform output -raw api_url 2>/dev/null || echo "Not available")
        
        echo ""
        echo "=========================================="
        echo "Your CI/CD Health Dashboard is now live!"
        echo "=========================================="
        echo "Instance IP: $INSTANCE_IP"
        echo "Application URL: $APP_URL"
        echo "API URL: $API_URL"
        echo ""
        echo "SSH Access:"
        echo "ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP"
        echo ""
        echo "Check Status:"
        echo "./check-status.sh"
        echo ""
        echo "Destroy Infrastructure:"
        echo "./destroy.sh"
        echo ""
        print_status "Deployment completed successfully! 🚀"
    else
        print_error "Deployment may have failed. Check the logs above."
    fi
}

# Main function
main() {
    print_header "CI/CD Health Dashboard - Quick Start"
    echo "=========================================="
    echo "This script will guide you through deploying"
    echo "your CI/CD Health Dashboard to AWS."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Check AWS configuration
    check_aws_config
    
    # Check SSH key
    check_ssh_key
    
    # Configure Terraform
    configure_terraform
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Show final information
    show_final_info
}

# Run main function
main "$@"
