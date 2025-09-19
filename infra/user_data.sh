#!/bin/bash

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Git
yum install -y git

# Install Node.js (for potential manual builds)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install additional utilities
yum install -y curl wget unzip

# Create application directory
mkdir -p /home/ec2-user/${app_name}
cd /home/ec2-user/${app_name}

# Clone the repository
git clone https://github.com/rahulmudpalliwar/assignment2_cicd_health_dashboard.git .

# Move into the CI-CD Health Dashboard directory
cd "CI-CD Health Dashboard"

# Set proper permissions
chown -R ec2-user:ec2-user /home/ec2-user/${app_name}

# Create environment file template
cat > /home/ec2-user/${app_name}/.env << EOF
# Database Configuration
DATABASE_URL=postgres://postgres:password@localhost:5432/cicd

# Application Configuration
PORT=3000
NODE_ENV=production

# Frontend Configuration
VITE_API_BASE_URL=http://localhost:3000

# GitHub Configuration (optional)
GITHUB_TOKEN=
GITHUB_REPOS=

# Jenkins Configuration (optional)
JENKINS_BASE_URL=
JENKINS_USER=
JENKINS_TOKEN=

# Email Configuration (optional)
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
ALERT_FROM="CI/CD Dashboard <noreply@example.com>"
ALERT_TO=
EOF

chown ec2-user:ec2-user /home/ec2-user/${app_name}/.env

# Create a simple startup script
cat > /home/ec2-user/${app_name}/start.sh << 'EOF'
#!/bin/bash
cd /home/ec2-user/cicd-health-dashboard
docker-compose down
docker-compose up -d --build
EOF

chmod +x /home/ec2-user/${app_name}/start.sh
chown ec2-user:ec2-user /home/ec2-user/${app_name}/start.sh

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log
