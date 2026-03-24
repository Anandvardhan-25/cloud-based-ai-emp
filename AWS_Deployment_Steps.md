# Steps to Deploy on AWS

## 1. Database Provisioning
1. Open the AWS Management Console & navigate to **Amazon RDS**.
2. Provision a **PostgreSQL 15+ Multi-AZ** instance for high availability.
3. Ensure the security group allows inbound traffic on port 5432 only from the VPC where your EKS/ECS clusters will be.
4. Keep the database credentials in **AWS Secrets Manager**.
5. Ensure required extensions are allowed (`pgcrypto`, `citext`, `pg_trgm`). Flyway will create them during migration.

## 2. Infrastructure Setup (EKS or ECS)
1. **Dockerize**: Build the Spring Boot Application and React Frontend into Docker containers (`Dockerfile` in `backend/` and `frontend/`).
2. Push images to **Amazon ECR** (Elastic Container Registry).
3. Create an **AWS ECS Fargate Cluster** (Serverless).
4. Define Task Definitions for Backend and Frontend. Mount the Secrets Manager values as environment variables directly to the Backend tasks (`DB_URL`, `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`).
5. Flyway migrations run automatically on application startup; ensure the DB user has privileges to create tables, indexes, and extensions.

## 3. Application Load Balancer (ALB)
1. Create an ALB mapping port 80/443 to the Backend and Frontend Target Groups.
2. Use **Path-Based Routing** to route `/api/*` to the Spring Boot backend target, and default `/` to the React frontend target.
3. Attach **AWS WAF** (Web Application Firewall) to protect against common exploits like SQL injection.

## 4. CI/CD Pipeline
1. Set up **AWS CodePipeline** or GitHub Actions.
2. On branch merge, build the backend via Maven, build the frontend via NPM, construct Docker images, and push them to ECR.
3. The pipeline will automatically force an ECS deployment update to pull the new image and roll out pods continuously with zero downtime.

## 5. Domain & HTTPS Certification
1. Point your Route 53 domain name to the Application Load Balancer.
2. Generate an SSL Certificate via **AWS Certificate Manager (ACM)** and attach it to the ALB listeners.
