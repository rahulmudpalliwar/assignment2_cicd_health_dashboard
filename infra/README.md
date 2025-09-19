# CI/CD Health Dashboard - AWS Infrastructure

This directory contains the Infrastructure-as-Code (IaC) configuration for deploying the CI/CD Health Dashboard to AWS using Terraform.

## Files Overview

### Core Terraform Files
- **`main.tf`** - Main infrastructure configuration (VPC, EC2, RDS, Security Groups)
- **`variables.tf`** - Variable definitions for customization
- **`outputs.tf`** - Output values after deployment
- **`terraform.tfvars.example`** - Example configuration file

### Scripts
- **`deploy.sh`** - Automated deployment script
- **`destroy.sh`** - Infrastructure cleanup script
- **`user_data.sh`** - EC2 instance initialization script

### Documentation
- **`AWS_SETUP_GUIDE.md`** - AWS Free Tier setup instructions
- **`README.md`** - This file

## Quick Start

### 1. Prerequisites
- AWS Free Tier account
- AWS CLI configured
- Terraform installed (>= 1.0)
- SSH key pair

### 2. Configuration
```bash
# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### 3. Deploy
```bash
# Make scripts executable
chmod +x deploy.sh destroy.sh

# Deploy infrastructure and application
./deploy.sh
```

### 4. Access
After deployment, access your application at:
- **Frontend**: `http://<INSTANCE_IP>:5173`
- **API**: `http://<INSTANCE_IP>:3000`

### 5. Cleanup
```bash
# Destroy all resources
./destroy.sh
```

## Infrastructure Components

### Compute
- **EC2 Instance**: t2.micro (Free Tier)
- **OS**: Amazon Linux 2
- **Storage**: 20 GB GP3 encrypted

### Database
- **RDS PostgreSQL**: db.t3.micro (Free Tier)
- **Version**: PostgreSQL 15.4
- **Storage**: 20 GB GP3 encrypted

### Networking
- **VPC**: Custom virtual private cloud
- **Subnet**: Public subnet
- **Security Groups**: Configured for web traffic
- **Elastic IP**: Static public IP

## Cost Management

All resources are designed to stay within AWS Free Tier limits:
- EC2: 750 hours/month free
- RDS: 750 hours/month free
- EBS: 30 GB free
- Data Transfer: 1 GB/month free

## Security

- SSH key-based authentication
- Security groups with minimal required ports
- Database access restricted to VPC
- EBS and RDS encryption enabled

## Troubleshooting

### Common Issues
1. **SSH Connection Failed**: Check security groups and key pair
2. **Application Not Accessible**: Verify Docker containers are running
3. **Database Connection Issues**: Check RDS endpoint and security groups

### Useful Commands
```bash
# Check infrastructure status
terraform show

# View outputs
terraform output

# SSH into instance
ssh -i ~/.ssh/id_rsa ec2-user@<INSTANCE_IP>

# Check application status
ssh -i ~/.ssh/id_rsa ec2-user@<INSTANCE_IP> \
  'cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard && docker-compose ps'
```

## Support

For issues and questions:
1. Check the [deployment.md](../deployment.md) for detailed instructions
2. Review the [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md) for AWS setup
3. Check the [prompts.md](../prompts.md) for AI-assisted development details
