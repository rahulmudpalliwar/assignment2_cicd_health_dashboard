# CI/CD Health Dashboard

Monitor the health of your CI/CD pipelines (GitHub Actions or Jenkins) with real-time metrics, historical builds, and email alerts. The stack includes: Node.js/Express backend, PostgreSQL, React (Vite) frontend, and Docker Compose for containerization.

## Features
- Success/Failure rate visualization
- Average build time tracking
- Last build status monitoring
- Latest builds list with detailed information
- Ingestion via polling (GitHub Actions/Jenkins) and webhooks
- Email alerts on pipeline failures
- Real-time dashboard updates
- Responsive React UI with modern design

## Quick Start (Docker)

### Prerequisites
- Docker and Docker Compose installed
- Git for cloning the repository

### Setup Instructions
1. Clone the repository:
```bash
git clone https://github.com/rahulmudpalliwar/assignment2_cicd_health_dashboard.git
cd assignment2_cicd_health_dashboard
```

2. Start all services:
```bash
docker compose up -d --build
```

3. Access the applications:
- **Frontend Dashboard**: http://localhost:5173
- **Backend API**: http://localhost:3000/api
- **Database**: localhost:5432 (PostgreSQL)

4. Verify the setup:
```bash
# Check API health
curl http://localhost:3000/api/health

# Check metrics
curl http://localhost:3000/api/metrics

# Check builds
curl http://localhost:3000/api/builds
```

### Development Setup (without Docker)
1. **Database Setup**:
```bash
# Install PostgreSQL locally
# Create database
createdb cicd

# Apply schema
psql -d cicd -f db/init.sql
```

2. **Backend Setup**:
```bash
cd backend
npm install
npm start
```

3. **Frontend Setup**:
```bash
cd frontend
npm install
npm run dev
```

## Environment Variables

### Core Configuration
```bash
PORT=3000
DATABASE_URL=postgres://postgres:postgres@db:5432/cicd
```

### GitHub Actions Integration (Optional)
```bash
GITHUB_TOKEN=your_github_personal_access_token
GITHUB_REPOS=owner1/repo1,owner2/repo2
```

### Jenkins Integration (Optional)
```bash
JENKINS_BASE_URL=http://jenkins.example.com
JENKINS_USER=your_jenkins_username
JENKINS_TOKEN=your_jenkins_api_token
```

### Email Alerting Configuration
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
ALERT_FROM="CI/CD Dashboard <noreply@example.com>"
ALERT_TO=alerts@example.com,team@example.com
```

## Architecture Summary

### System Overview
The CI/CD Health Dashboard is a full-stack application designed to monitor and visualize the health of CI/CD pipelines. It follows a microservices architecture with clear separation of concerns.

### Technology Stack
- **Frontend**: React 18 with TypeScript, Vite build tool
- **Backend**: Node.js with Express.js framework
- **Database**: PostgreSQL 15 with proper indexing
- **Containerization**: Docker with Docker Compose orchestration
- **Real-time Updates**: Polling mechanism with 15-second intervals

### Component Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend│    │  Express Backend│    │  PostgreSQL DB │
│   (Port 5173)   │◄──►│   (Port 3000)   │◄──►│   (Port 5432)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Metrics Cards  │    │  REST API       │    │  Builds Table  │
│  Builds Table   │    │  Polling Engine │    │  Alerts Table  │
│  Real-time UI   │    │  Email Service  │    │  Indexes       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Data Flow
1. **Data Ingestion**: Backend polls GitHub Actions and Jenkins APIs
2. **Data Storage**: Build information stored in PostgreSQL with proper indexing
3. **Data Processing**: Metrics calculated using SQL aggregations
4. **Data Presentation**: React frontend fetches and displays data
5. **Alerting**: Email notifications sent on build failures

### API Endpoints
- `GET /api/health` - Service health check
- `GET /api/metrics` - Success/failure rates and build statistics
- `GET /api/builds` - List of recent builds with pagination
- `GET /api/builds/:id/logs` - Build logs (if available)
- `POST /api/webhook/github` - GitHub webhook endpoint
- `POST /api/webhook/jenkins` - Jenkins webhook endpoint

## How AI Tools Were Used

### Development Process
This project was developed using AI-assisted coding tools including Cursor, GitHub Copilot, and ChatGPT. The AI tools were instrumental in accelerating development and ensuring best practices.

### Prompt Examples

#### 1. Project Architecture Design
**Prompt**: "Design a CI/CD pipeline health dashboard architecture with Node.js backend, React frontend, PostgreSQL database, and Docker containerization. Include polling mechanisms for GitHub Actions and Jenkins, webhook endpoints, and email alerting system."

**AI Response**: Generated complete system architecture with component separation, data flow diagrams, and technology recommendations.

#### 2. Database Schema Design
**Prompt**: "Create a PostgreSQL schema for storing CI/CD build information with fields for tool type, external ID, repository, branch, status, timestamps, duration, and logs. Include proper indexing for performance."

**AI Response**: Generated optimized schema with:
```sql
CREATE TABLE builds (
  id SERIAL PRIMARY KEY,
  tool TEXT NOT NULL,
  external_id TEXT UNIQUE NOT NULL,
  repo TEXT,
  branch TEXT,
  status TEXT,
  conclusion TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  url TEXT,
  logs TEXT
);
```

#### 3. React Component Development
**Prompt**: "Build a React component for displaying CI/CD metrics with TypeScript. Include success rate, failure rate, average build time, and last build status. Use modern styling and responsive design."

**AI Response**: Generated MetricsCard and BuildsTable components with proper TypeScript interfaces and modern CSS styling.

#### 4. API Development
**Prompt**: "Implement Express.js API endpoints for CI/CD metrics with proper error handling, CORS support, and PostgreSQL integration. Include health checks and data validation."

**AI Response**: Generated complete API structure with proper middleware, error handling, and database queries.

#### 5. Docker Configuration
**Prompt**: "Create Docker Compose configuration for a full-stack CI/CD dashboard with PostgreSQL, Node.js backend, and React frontend. Include proper networking and volume management."

**AI Response**: Generated multi-service Docker Compose setup with proper service dependencies and port mapping.

### AI Tool Benefits
- **Rapid Prototyping**: Quick generation of boilerplate code
- **Best Practices**: AI suggested modern patterns and conventions
- **Error Prevention**: AI helped identify potential issues early
- **Documentation**: Assisted in creating comprehensive documentation
- **Code Quality**: Ensured consistent coding standards

## Key Learning and Assumptions

### Technical Learnings

#### 1. Microservices Architecture
- **Learning**: Proper separation of frontend, backend, and database services
- **Benefit**: Independent scaling and deployment of components
- **Implementation**: Docker Compose for local development, containerized deployment

#### 2. Real-time Data Synchronization
- **Learning**: Polling vs webhook approaches for CI/CD data ingestion
- **Challenge**: Rate limiting considerations for external APIs
- **Solution**: Configurable polling intervals and webhook endpoints

#### 3. Database Design
- **Learning**: Proper indexing for time-series data queries
- **Optimization**: Composite indexes on frequently queried columns
- **Performance**: Efficient aggregation queries for metrics calculation

#### 4. Frontend State Management
- **Learning**: React hooks for real-time data updates
- **Pattern**: useEffect for data fetching and cleanup
- **UX**: Automatic refresh intervals for live dashboard updates

### Assumptions and Design Decisions

#### 1. Polling Strategy
- **Assumption**: Conservative 60-second polling intervals to avoid rate limits
- **Rationale**: Balance between real-time updates and API courtesy
- **Flexibility**: Configurable intervals via environment variables

#### 2. Data Retention
- **Assumption**: Build history should be preserved for trend analysis
- **Decision**: No automatic data cleanup implemented
- **Future**: Could add retention policies for long-term storage

#### 3. Alert Deduplication
- **Assumption**: Email alerts should be sent once per build failure
- **Implementation**: Database tracking of sent alerts to prevent duplicates
- **Benefit**: Prevents notification spam for long-running failures

#### 4. Error Handling
- **Assumption**: Graceful degradation when external services are unavailable
- **Implementation**: Try-catch blocks around external API calls
- **User Experience**: Dashboard remains functional with cached data

#### 5. Security Considerations
- **Assumption**: Environment-based configuration for sensitive data
- **Implementation**: .env files for local development, secrets management for production
- **Best Practice**: No hardcoded credentials in source code

### Performance Considerations
- **Database Indexing**: Optimized queries for build history and metrics
- **Caching**: Frontend caching of API responses for better UX
- **Resource Management**: Proper cleanup of intervals and event listeners
- **Scalability**: Containerized architecture for horizontal scaling

### Future Enhancements
- **Authentication**: User login and role-based access control
- **Advanced Metrics**: Trend analysis and predictive insights
- **Integration**: Support for additional CI/CD platforms (GitLab, Azure DevOps)
- **Notifications**: Slack, Teams, and other notification channels
- **Customization**: User-configurable dashboards and alerts

## Troubleshooting

### Common Issues

#### 1. Database Connection Issues
```bash
# Check if PostgreSQL is running
docker compose ps

# View database logs
docker compose logs db

# Reset database
docker compose down -v
docker compose up -d
```

#### 2. Backend API Issues
```bash
# Check backend logs
docker compose logs backend

# Test API health
curl http://localhost:3000/api/health

# Restart backend service
docker compose restart backend
```

#### 3. Frontend Build Issues
```bash
# Check frontend logs
docker compose logs frontend

# Rebuild frontend
docker compose build frontend
docker compose up -d frontend
```

#### 4. Port Conflicts
```bash
# Check port usage
netstat -tulpn | grep :3000
netstat -tulpn | grep :5173

# Change ports in docker-compose.yml if needed
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the GitHub repository
- Check the troubleshooting section above
- Review the documentation and examples

---

**Built with ❤️ using AI-assisted development tools**
