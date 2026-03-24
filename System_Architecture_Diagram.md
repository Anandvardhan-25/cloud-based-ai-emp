# System Architecture Diagram (Cloud Deployment Ready)

```mermaid
graph TD
    User([End User / Admin]) -->|HTTPS| CloudFront[AWS CloudFront / WAF]
    CloudFront --> ALB[Application Load Balancer]
    
    subgraph "AWS VPC (Private Subnets mostly)"
        ALB -->|Route traffic| APIGateway[API Gateway / Ingress]
        
        subgraph "EKS / ECS Cluster (Microservices)"
            APIGateway --> Frontend[React Frontend Container]
            APIGateway --> BackendAdmin[Spring Boot: Admin & Core Service]
            APIGateway --> BackendAI[Spring Boot: AI Microservice]
        end
        
        BackendAdmin -->|Reads/Writes| PrimaryDB[(Amazon RDS PostgreSQL Array)]
        BackendAI -->|Reads Metrics, Stores Logs| PrimaryDB
        BackendAI -->|External Call| OpenAI[External LLM Provider]
        
        PrimaryDB -->|Replication| StandbyDB[(RDS Multi-AZ Standby)]
    end
    
    BackendAdmin -->|Metrics| CloudWatch[AWS CloudWatch]
    BackendAI -->|Logs| CloudWatch
```

## Architecture Notes
- **Frontend**: Served via S3+CloudFront or inside a stateless ECS/EKS container.
- **Backend Layers**: Implemented in Spring Boot layered structure (Controller -> Service -> Repository).
- **Security**: JWT tokens verified at the API Gateway or individual microservices.
- **Database**: PostgreSQL handles structured, relational data (UUIDs, JSONB for AI logs).
- **Scalability**: ECS/EKS allows scaling the backend pods up and down horizontally.
