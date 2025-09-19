#!/bin/bash

# Destruction script for CI/CD Health Dashboard AWS infrastructure
# This script destroys all AWS resources created by Terraform

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

# Confirm destruction
confirm_destruction() {
    print_warning "This will DESTROY all AWS resources created for the CI/CD Health Dashboard!"
    print_warning "This action cannot be undone!"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Destruction cancelled."
        exit 0
    fi
}

# Main destruction function
main() {
    print_status "Starting infrastructure destruction..."
    
    # Check if we're in the right directory
    if [ ! -f "main.tf" ]; then
        print_error "Please run this script from the infra directory"
        exit 1
    fi
    
    # Confirm destruction
    confirm_destruction
    
    # Show what will be destroyed
    print_status "Planning destruction..."
    terraform plan -destroy
    
    # Apply destruction
    print_status "Destroying infrastructure..."
    terraform destroy -auto-approve
    
    print_status "Infrastructure destruction completed!"
    print_status "All AWS resources have been removed."
}

# Run main function
main "$@"
