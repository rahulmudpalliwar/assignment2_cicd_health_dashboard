#!/bin/bash

# Status check script for CI/CD Health Dashboard deployment
# This script checks the status of the deployed infrastructure and application

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

# Check if Terraform is initialized
check_terraform() {
    print_header "Checking Terraform Status"
    
    if [ ! -f "terraform.tfstate" ]; then
        print_error "Terraform state not found. Run 'terraform init' first."
        return 1
    fi
    
    print_status "Terraform state found."
    
    # Get outputs
    if terraform output instance_public_ip > /dev/null 2>&1; then
        INSTANCE_IP=$(terraform output -raw instance_public_ip)
        APP_URL=$(terraform output -raw application_url)
        API_URL=$(terraform output -raw api_url)
        
        print_status "Instance IP: $INSTANCE_IP"
        print_status "Application URL: $APP_URL"
        print_status "API URL: $API_URL"
    else
        print_error "Terraform outputs not available. Infrastructure may not be deployed."
        return 1
    fi
}

# Check EC2 instance status
check_ec2() {
    print_header "Checking EC2 Instance Status"
    
    if [ -z "$INSTANCE_IP" ]; then
        print_error "Instance IP not available"
        return 1
    fi
    
    # Check if instance is reachable via SSH
    if ssh -i ~/.ssh/id_rsa -o ConnectTimeout=10 -o BatchMode=yes ec2-user@$INSTANCE_IP exit 2>/dev/null; then
        print_status "EC2 instance is reachable via SSH"
    else
        print_warning "EC2 instance is not reachable via SSH"
        return 1
    fi
}

# Check application status
check_application() {
    print_header "Checking Application Status"
    
    if [ -z "$INSTANCE_IP" ]; then
        print_error "Instance IP not available"
        return 1
    fi
    
    # Check Docker containers
    print_status "Checking Docker containers..."
    CONTAINER_STATUS=$(ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP \
        'cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard && docker-compose ps --format json' 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        print_status "Docker containers status retrieved"
        echo "$CONTAINER_STATUS" | jq -r '.[] | "\(.Name): \(.State)"' 2>/dev/null || echo "$CONTAINER_STATUS"
    else
        print_warning "Could not retrieve Docker container status"
    fi
    
    # Check if application is responding
    print_status "Checking application endpoints..."
    
    # Check API
    if curl -s -f "$API_URL/api/health" > /dev/null 2>&1; then
        print_status "API is responding"
    else
        print_warning "API is not responding"
    fi
    
    # Check Frontend
    if curl -s -f "$APP_URL" > /dev/null 2>&1; then
        print_status "Frontend is responding"
    else
        print_warning "Frontend is not responding"
    fi
}

# Check database connectivity
check_database() {
    print_header "Checking Database Status"
    
    if [ -z "$INSTANCE_IP" ]; then
        print_error "Instance IP not available"
        return 1
    fi
    
    # Check database container
    DB_STATUS=$(ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP \
        'cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard && docker-compose ps db --format json' 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        print_status "Database container status checked"
        echo "$DB_STATUS" | jq -r '.[0].State' 2>/dev/null || echo "Database status: Unknown"
    else
        print_warning "Could not check database status"
    fi
}

# Show logs
show_logs() {
    print_header "Recent Application Logs"
    
    if [ -z "$INSTANCE_IP" ]; then
        print_error "Instance IP not available"
        return 1
    fi
    
    print_status "Fetching recent logs..."
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP \
        'cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard && docker-compose logs --tail=20'
}

# Main function
main() {
    print_header "CI/CD Health Dashboard Status Check"
    echo "========================================"
    
    # Check if we're in the right directory
    if [ ! -f "main.tf" ]; then
        print_error "Please run this script from the infra directory"
        exit 1
    fi
    
    # Run checks
    check_terraform
    if [ $? -eq 0 ]; then
        check_ec2
        check_application
        check_database
        
        echo ""
        print_header "Quick Commands"
        echo "==============="
        echo "SSH into instance:"
        echo "ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP"
        echo ""
        echo "View application logs:"
        echo "ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP 'cd /home/ec2-user/cicd-health-dashboard/CI-CD\\ Health\\ Dashboard && docker-compose logs -f'"
        echo ""
        echo "Restart application:"
        echo "ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP 'cd /home/ec2-user/cicd-health-dashboard/CI-CD\\ Health\\ Dashboard && docker-compose restart'"
        
        # Ask if user wants to see logs
        echo ""
        read -p "Do you want to see recent application logs? (y/n): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            show_logs
        fi
    else
        print_error "Infrastructure not properly deployed"
        exit 1
    fi
}

# Run main function
main "$@"
