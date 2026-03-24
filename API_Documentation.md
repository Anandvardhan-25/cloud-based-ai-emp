# Cloud-Based AI Workforce Intelligence Platform - API Documentation

## Authentication (JWT)

Base Path: `/api/auth`

All protected endpoints require:

`Authorization: Bearer <JWT>`

### POST /api/auth/register
Registers a user (dev-friendly; for production, restrict elevated roles).

Request:
```json
{
  "username": "johndoe",
  "email": "johndoe@company.com",
  "password": "Password123!",
  "roles": ["EMPLOYEE"]
}
```

Response:
```json
{
  "tokenType": "Bearer",
  "accessToken": "<jwt>",
  "expiresInSeconds": 3600,
  "username": "johndoe",
  "roles": ["EMPLOYEE"]
}
```

### POST /api/auth/employee/login
Request:
```json
{ "username": "johndoe", "password": "Password123!" }
```

### POST /api/auth/admin/login
Request:
```json
{ "username": "admin", "password": "AdminPassword123!" }
```

## Employees

Base Path: `/api/employees` (RBAC: `ADMIN|HR|MANAGER`)

- `GET /api/employees?page=0&size=10&keyword=anand`
- `POST /api/employees`
- `GET /api/employees/{id}`
- `PUT /api/employees/{id}`
- `DELETE /api/employees/{id}`

## Projects

Base Path: `/api/projects` (write RBAC: `ADMIN|MANAGER`)

- `POST /api/projects`
- `GET /api/projects?page=0&size=10&keyword=alpha`
- `GET /api/projects/{id}`
- `PUT /api/projects/{id}`
- `DELETE /api/projects/{id}`

## Tasks

Base Path: `/api/tasks`

- `GET /api/tasks` (optional filters: `projectId`, `assigneeId`, `status`)
- `POST /api/tasks`
- `PUT /api/tasks/{id}/status`

## Performance

Base Path: `/api/performance` (RBAC: `ADMIN|HR|MANAGER`)

- `POST /api/performance/metrics`
- `GET /api/performance/metrics/employee/{employeeId}`
- `GET /api/performance/evaluate/employee/{employeeId}?periodStart=2026-01-01&periodEnd=2026-03-31`

## Training

Base Path: `/api/training` (RBAC: `ADMIN|HR|MANAGER`)

- `POST /api/training/history`
- `GET /api/training/history/employee/{employeeId}`
- `GET /api/training/recommendations/employee/{employeeId}`

## AI Intelligence (mock)

Base Path: `/api/ai` (RBAC: `ADMIN|HR|MANAGER`)

- `POST /api/ai/employee/{id}/performance-summary`
- `POST /api/ai/employee/{id}/skill-roadmap`
- `POST /api/ai/employee/{id}/hr-feedback-email`
