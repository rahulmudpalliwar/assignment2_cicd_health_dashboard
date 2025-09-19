# AWS Free Tier Setup Guide

This guide will help you set up an AWS Free Tier account and configure it for deploying the CI/CD Health Dashboard.

## Step 1: Create AWS Free Tier Account

1. **Visit AWS Free Tier**: Go to [https://aws.amazon.com/free/](https://aws.amazon.com/free/)
2. **Click "Create Free Account"**
3. **Provide Account Information**:
   - Email address
   - Password (must be strong)
   - AWS account name

4. **Contact Information**:
   - Full name
   - Phone number
   - Country/region

5. **Payment Information**:
   - Credit card (required for verification, but won't be charged for free tier usage)
   - Billing address

6. **Identity Verification**:
   - Phone verification via SMS or voice call

7. **Support Plan**:
   - Select "Basic Plan" (free)

## Step 2: Configure AWS CLI

### Install AWS CLI

**On Linux/WSL:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**On macOS:**
```bash
brew install awscli
```

**On Windows:**
Download from: https://aws.amazon.com/cli/

### Configure AWS CLI

1. **Get your AWS credentials**:
   - Go to AWS Console → IAM → Users → Your User → Security credentials
   - Create a new access key
   - Download the credentials CSV file

2. **Configure AWS CLI**:
```bash
aws configure
```

Enter the following when prompted:
- **AWS Access Key ID**: [Your access key]
- **AWS Secret Access Key**: [Your secret key]
- **Default region name**: `us-east-1` (recommended for free tier)
- **Default output format**: `json`

## Step 3: Generate SSH Key Pair

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Display public key (you'll need this for Terraform)
cat ~/.ssh/id_rsa.pub
```

## Step 4: Verify AWS Setup

```bash
# Test AWS CLI connection
aws sts get-caller-identity

# List available regions
aws ec2 describe-regions --query 'Regions[].RegionName' --output table
```

## Step 5: Free Tier Limits and Monitoring

### Important Free Tier Limits:

1. **EC2**: 750 hours/month of t2.micro instances
2. **RDS**: 750 hours/month of db.t3.micro instances
3. **EBS Storage**: 30 GB of General Purpose (gp2) volumes
4. **Data Transfer**: 1 GB/month out to internet

### Set up Billing Alerts:

1. Go to AWS Console → Billing → Billing preferences
2. Enable "Receive Billing Alerts"
3. Create CloudWatch alarms for spending thresholds

## Step 6: Security Best Practices

1. **Enable MFA** on your root account
2. **Create IAM users** instead of using root account
3. **Use least privilege principle** for IAM policies
4. **Regularly review** your AWS usage and costs

## Troubleshooting

### Common Issues:

1. **"NoCredentialsError"**: AWS CLI not configured properly
   - Solution: Run `aws configure` again

2. **"AccessDenied"**: Insufficient permissions
   - Solution: Ensure your IAM user has EC2, RDS, and VPC permissions

3. **"Region not supported"**: Some regions don't support all free tier services
   - Solution: Use `us-east-1` (N. Virginia) region

### Getting Help:

- AWS Free Tier FAQ: https://aws.amazon.com/free/free-tier-faqs/
- AWS Support Forums: https://forums.aws.amazon.com/
- AWS Documentation: https://docs.aws.amazon.com/

## Next Steps

Once you've completed this setup:

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update the values in `terraform.tfvars` with your configuration
3. Run the deployment script: `./deploy.sh`

Your CI/CD Health Dashboard will be deployed to AWS and accessible via a public IP address!
