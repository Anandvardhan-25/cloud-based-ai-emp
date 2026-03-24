# AI Integration Explanation

## Objective
The platform leverages Generative AI to automate tedious HR, management, and intelligence tasks. It uses contextual performance, skill, and productivity data to provide tailored insights.

## Current Setup (Mock Integration)
In the current phase, the AI Intelligence Layer is abstracted through the `AiService`. This service returns simulated (mock) responses designed to mimic how an actual Large Language Model (LLM) would respond given specific prompt inputs (e.g., Performance Reviews, Skill Roadmaps). 

All AI interactions (inputs and outputs) are logged securely in the `ai_feedback_logs` table (using `JSONB` for payloads). This provides full observability into AI decisions, allowing HR to trace any generated recommendation back to the context that triggered it.

## Future Production Integration Structure
When switching to a real LLM API (e.g., OpenAI GPT-4, AWS Bedrock, or Gemini):

1. **Prompt Engineering Engine**: Business context (e.g. Employee metrics, task completion rate, skill gaps) is injected into templated prompts.
2. **AI Microservice**: A dedicated Spring Boot microservice will communicate over REST/gRPC with the LLM Provider endpoint via API keys or IAM roles (if using AWS Bedrock).
3. **Asynchronous Processing**: Since LLM generation can be slow, requests for Performance Reviews will utilize message queues (e.g. AWS SQS or RabbitMQ). The API will return an HTTP 202 (Accepted) and notify the user via WebSockets or email when the AI generation completes.
4. **Data Privacy**: No PII (Personally Identifiable Information) beyond standard names will be sent to the public model, enforcing strict masking rules or utilizing a privately hosted VPC LLM.
