# CI/CD Health Dashboard - AWS Deployment Guide

This guide will walk you through deploying your CI/CD Health Dashboard to AWS using Infrastructure-as-Code (Terraform).

## Prerequisites

Before starting the deployment, ensure you have:

1. **AWS Free Tier Account** - See [AWS_SETUP_GUIDE.md](infra/AWS_SETUP_GUIDE.md)
2. **AWS CLI configured** with your credentials
3. **Terraform installed** (version >= 1.0)
4. **SSH key pair** generated
5. **Git** installed

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/rahulmudpalliwar/assignment2_cicd_health_dashboard.git
cd assignment2_cicd_health_dashboard

# Make deployment script executable
chmod +x infra/deploy.sh
```

### 2. Configure Terraform Variables

```bash
# Copy the example variables file
cp infra/terraform.tfvars.example infra/terraform.tfvars

# Edit the variables file
nano infra/terraform.tfvars
```

Update the following variables in `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Application Configuration
app_name = "cicd-health-dashboard"

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# Instance Configuration (Free Tier)
instance_type     = "t2.micro"
db_instance_class = "db.t3.micro"

# SSH Key Configuration
public_key_path = "~/.ssh/id_rsa.pub"

# Database Configuration
db_password = "your-secure-database-password-here"
```

### 3. Deploy Infrastructure and Application

```bash
# Run the deployment script
cd infra
./deploy.sh
```

The script will:
- Initialize Terraform
- Plan the infrastructure deployment
- Apply the infrastructure (EC2, RDS, VPC, Security Groups)
- Deploy your application code
- Start the Docker containers

### 4. Access Your Application

After deployment completes, you'll see output like:

```
==========================================
CI/CD Health Dashboard Deployment Summary
==========================================
Instance IP: 54.123.456.789
Application URL: http://54.123.456.789:5173
API URL: http://54.123.456.789:3000
SSH Command: ssh -i ~/.ssh/id_rsa ec2-user@54.123.456.789
```

## Manual Deployment Steps

If you prefer to run Terraform commands manually:

### 1. Initialize Terraform

```bash
cd infra
terraform init
```

### 2. Plan Deployment

```bash
terraform plan
```

### 3. Apply Infrastructure

```bash
terraform apply
```

### 4. Get Outputs

```bash
terraform output
```

### 5. Deploy Application

```bash
# Get the instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# Wait for instance to be ready
sleep 60

# Update environment variables with RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP \
  "cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard && \
   echo 'DATABASE_URL=postgres://postgres:password@$RDS_ENDPOINT:5432/cicd' > .env"

# Start the application
ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP \
  "cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard && \
   docker-compose up -d --build"
```

## Infrastructure Components

The Terraform configuration creates:

### Compute
- **EC2 Instance**: t2.micro (Free Tier eligible)
- **Operating System**: Amazon Linux 2
- **Storage**: 20 GB GP3 encrypted EBS volume
- **Public IP**: Elastic IP for static access

### Database
- **RDS PostgreSQL**: db.t3.micro (Free Tier eligible)
- **Version**: PostgreSQL 15.4
- **Storage**: 20 GB GP3 encrypted
- **Backup**: 7-day retention

### Networking
- **VPC**: Custom virtual private cloud
- **Subnet**: Public subnet with internet access
- **Security Groups**: Configured for web traffic and SSH
- **Internet Gateway**: For public internet access

### Security
- **SSH Access**: Key-based authentication
- **Web Ports**: 80, 443, 3000, 5173
- **Database Access**: Internal VPC only
- **Encryption**: EBS and RDS encryption enabled

## Application Architecture

The deployed application consists of:

```
Internet → EC2 Instance (Public IP)
                ↓
    ┌─────────────────────────────┐
    │  Docker Compose Stack       │
    │  ┌─────────────────────────┐│
    │  │  React Frontend (5173)  ││
    │  └─────────────────────────┘│
    │  ┌─────────────────────────┐│
    │  │  Node.js API (3000)     ││
    │  └─────────────────────────┘│
    │  ┌─────────────────────────┐│
    │  │  PostgreSQL (5432)      ││
    │  └─────────────────────────┘│
    └─────────────────────────────┘
                ↓
         RDS PostgreSQL
```

## Monitoring and Maintenance

### Check Application Status

```bash
# SSH into the instance
ssh -i ~/.ssh/id_rsa ec2-user@<INSTANCE_IP>

# Check Docker containers
cd /home/ec2-user/cicd-health-dashboard/CI-CD\ Health\ Dashboard
docker-compose ps

# View logs
docker-compose logs -f
```

### Application Logs

```bash
# Backend logs
docker-compose logs -f backend

# Frontend logs
docker-compose logs -f frontend

# Database logs
docker-compose logs -f db
```

### Restart Application

```bash
# Restart all services
docker-compose restart

# Rebuild and restart
docker-compose up -d --build
```

## Cost Management

### Free Tier Usage

The deployment uses AWS Free Tier eligible resources:
- **EC2**: t2.micro (750 hours/month free)
- **RDS**: db.t3.micro (750 hours/month free)
- **EBS**: 20 GB (30 GB free tier limit)
- **Data Transfer**: Minimal for dashboard usage

### Cost Monitoring

1. **AWS Cost Explorer**: Monitor spending in real-time
2. **Billing Alerts**: Set up CloudWatch alarms
3. **Resource Tagging**: Track costs by project

### Cleanup

To avoid charges, destroy the infrastructure when not needed:

```bash
cd infra
terraform destroy
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH key is correct
   - Check security group allows SSH (port 22)
   - Ensure instance is running

2. **Application Not Accessible**
   - Check security groups allow HTTP/HTTPS traffic
   - Verify Docker containers are running
   - Check application logs for errors

3. **Database Connection Issues**
   - Verify RDS endpoint is correct
   - Check security groups allow database access
   - Ensure database is running

4. **Terraform Errors**
   - Check AWS credentials are configured
   - Verify region supports all required services
   - Check for resource naming conflicts

### Getting Help

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Terraform Documentation**: https://www.terraform.io/docs/
- **Docker Documentation**: https://docs.docker.com/

## Security Considerations

1. **Change Default Passwords**: Update database passwords
2. **Restrict SSH Access**: Use specific IP ranges if possible
3. **Regular Updates**: Keep system and Docker images updated
4. **Monitor Access**: Review CloudTrail logs regularly
5. **Backup Data**: Regular RDS snapshots

## Next Steps

After successful deployment:

1. **Configure GitHub/Jenkins Integration**: Add webhook URLs
2. **Set up Email Alerts**: Configure SMTP settings
3. **Monitor Performance**: Set up CloudWatch monitoring
4. **Scale as Needed**: Upgrade instance types if required
5. **Set up CI/CD**: Automate deployments from your repository

Your CI/CD Health Dashboard is now live on AWS! 🚀
