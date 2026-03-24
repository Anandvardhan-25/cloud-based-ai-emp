# Employee Management System (Cloud Ready)

Full Stack Application built using:

Backend:
- Spring Boot
- PostgreSQL
- JPA / Hibernate
- Flyway migrations
- REST APIs
- JWT authentication (RBAC)

Frontend:
- React.js
- Axios

Features:
- Add Employee
- Update Employee
- Delete Employee
- Search Employee
- Pagination
- Global Exception Handling
- Projects + Tasks
- Performance evaluation (placeholder scoring)
- Training recommendations (placeholder)
- AI module abstraction + mock generator (logs persisted)

## Local Setup (PostgreSQL)

1) Install PostgreSQL
- Windows: install via PostgreSQL installer (15+) and include `psql` in PATH
- macOS: `brew install postgresql@15`
- Linux (Debian/Ubuntu): `sudo apt-get install postgresql`

2) Create database + user (example)
```sql
CREATE DATABASE workforce_ai;
CREATE USER workforce_ai WITH ENCRYPTED PASSWORD 'change-me';
GRANT ALL PRIVILEGES ON DATABASE workforce_ai TO workforce_ai;
```

3) Configure env vars (PowerShell example)
```powershell
$env:DB_URL="jdbc:postgresql://localhost:5432/workforce_ai"
$env:DB_USER="workforce_ai"
$env:DB_PASSWORD="change-me"
$env:JWT_SECRET="change-me-in-prod-change-me-in-prod-32bytes-min"
```

4) Run backend (Flyway runs on startup)
```powershell
cd backend
./mvnw spring-boot:run
```

## API Quick Test (curl)

Register (dev-friendly):
```bash
curl -X POST http://localhost:8080/api/auth/register -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"email\":\"admin@company.com\",\"password\":\"AdminPassword123!\",\"roles\":[\"ADMIN\"]}"
```

Create Project (use token from response):
```bash
curl -X POST http://localhost:8080/api/projects -H "Authorization: Bearer <JWT>" -H "Content-Type: application/json" -d "{\"projectCode\":\"PRJ-001\",\"name\":\"Alpha\"}"
```

Author:
Anand Vardhan Butti
