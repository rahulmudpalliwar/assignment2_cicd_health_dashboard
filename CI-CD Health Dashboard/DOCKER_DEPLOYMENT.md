# Docker Deployment Guide

This document provides comprehensive instructions for containerizing and deploying the CI/CD Health Dashboard using Docker.

## Containerization Overview

The application is fully containerized using Docker with the following architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                     │
├─────────────────┬─────────────────┬─────────────────────────┤
│   PostgreSQL    │   Node.js API   │    React Frontend      │
│   (Port 5432)   │   (Port 3000)   │    (Port 5173)         │
└─────────────────┴─────────────────┴─────────────────────────┘
```

## Container Structure

### 1. Database Container (PostgreSQL)
- **Image**: `postgres:15`
- **Port**: 5432
- **Volume**: Persistent data storage
- **Health Check**: Database connectivity verification

### 2. Backend Container (Node.js/Express)
- **Base Image**: `node:20-alpine`
- **Port**: 3000
- **Dependencies**: PostgreSQL database
- **Health Check**: API endpoint verification

### 3. Frontend Container (React)
- **Base Image**: `node:20-alpine`
- **Port**: 5173
- **Dependencies**: Backend API
- **Health Check**: Frontend accessibility

## Docker Files

### Backend Dockerfile
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci || npm install
COPY . .
EXPOSE 3000
CMD ["npm","start"]
```

### Frontend Dockerfile
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci || npm install
COPY . .
EXPOSE 5173
ENV VITE_API_BASE_URL="http://localhost:3000"
CMD ["npm", "run", "dev", "--", "--host"]
```

### Docker Compose Configuration
```yaml
version: '3.9'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: cicd
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./db/init.sql:/docker-entrypoint-initdb.d/01-init.sql:ro
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://postgres:postgres@db:5432/cicd
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build: ./frontend
    environment:
      - VITE_API_BASE_URL=http://localhost:3000
    depends_on:
      - backend
    ports:
      - "5173:5173"

volumes:
  db_data:
```

## Deployment Instructions

### Prerequisites
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

### Step 1: Clone Repository
```bash
git clone https://github.com/rahulmudpalliwar/assignment2_cicd_health_dashboard.git
cd assignment2_cicd_health_dashboard
```

### Step 2: Build and Start Services
```bash
# Build all containers
docker compose build

# Start all services in detached mode
docker compose up -d

# View logs
docker compose logs -f
```

### Step 3: Verify Deployment
```bash
# Check service status
docker compose ps

# Test API health
curl http://localhost:3000/api/health

# Test frontend
curl http://localhost:5173
```

### Step 4: Access Applications
- **Frontend Dashboard**: http://localhost:5173
- **Backend API**: http://localhost:3000/api
- **Database**: localhost:5432

## Production Deployment

### Environment Configuration
Create `.env` file for production settings:
```bash
# Database
POSTGRES_PASSWORD=your_secure_password
POSTGRES_USER=your_db_user

# Backend
NODE_ENV=production
DATABASE_URL=postgres://user:pass@db:5432/cicd

# GitHub Integration
GITHUB_TOKEN=your_github_token
GITHUB_REPOS=owner/repo

# Email Alerts
SMTP_HOST=smtp.gmail.com
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

### Production Docker Compose
```yaml
version: '3.9'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: cicd
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./db/init.sql:/docker-entrypoint-initdb.d/01-init.sql:ro
    ports:
      - "5432:5432"
    restart: unless-stopped

  backend:
    build: ./backend
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - GITHUB_REPOS=${GITHUB_REPOS}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_USER=${SMTP_USER}
      - SMTP_PASS=${SMTP_PASS}
    depends_on:
      - db
    ports:
      - "3000:3000"
    restart: unless-stopped

  frontend:
    build: ./frontend
    environment:
      - VITE_API_BASE_URL=http://localhost:3000
    ports:
      - "5173:5173"
    restart: unless-stopped

volumes:
  db_data:
```

## Container Management

### Useful Commands
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart specific service
docker compose restart backend

# View logs
docker compose logs -f backend

# Scale services
docker compose up -d --scale backend=2

# Clean up
docker compose down -v
docker system prune -f
```

### Health Monitoring
```bash
# Check service health
docker compose ps

# Monitor resource usage
docker stats

# Inspect container
docker compose exec backend sh
```

## Security Considerations

### Container Security
- Use non-root users in containers
- Implement resource limits
- Regular security updates
- Network isolation

### Data Security
- Encrypt sensitive environment variables
- Use secrets management
- Implement backup strategies
- Monitor access logs

## Troubleshooting

### Common Issues

#### 1. Port Conflicts
```bash
# Check port usage
netstat -tulpn | grep :3000
netstat -tulpn | grep :5173

# Change ports in docker-compose.yml
```

#### 2. Database Connection Issues
```bash
# Check database logs
docker compose logs db

# Test database connectivity
docker compose exec db psql -U postgres -d cicd
```

#### 3. Build Failures
```bash
# Clean build cache
docker compose build --no-cache

# Check Dockerfile syntax
docker build -t test ./backend
```

#### 4. Memory Issues
```bash
# Check container memory usage
docker stats

# Increase memory limits in docker-compose.yml
```

## Performance Optimization

### Resource Limits
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
```

### Caching Strategies
- Multi-stage builds for smaller images
- Layer caching for faster builds
- Volume caching for node_modules

### Monitoring
- Container health checks
- Resource usage monitoring
- Application metrics collection

## Conclusion

The CI/CD Health Dashboard is fully containerized and ready for deployment in any Docker environment. The containerization provides:

- **Isolation**: Each service runs in its own container
- **Scalability**: Easy horizontal scaling
- **Portability**: Run anywhere Docker is available
- **Consistency**: Same environment across development and production
- **Maintainability**: Easy updates and rollbacks

For additional support, refer to the main README.md or create an issue in the GitHub repository.
