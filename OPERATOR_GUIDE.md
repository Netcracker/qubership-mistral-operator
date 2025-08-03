# Mistral Operator: Comprehensive Guide

This repository contains the **Mistral Operator** - a Kubernetes operator that automates the deployment and management of the Mistral workflow engine.

## Quick Reference

### Key Concepts
- **CR (Custom Resource)**: `MistralService` - defines how Mistral should be deployed
- **Helm**: Package manager that templates Kubernetes manifests
- **Operator Pattern**: Watches for MistralService resources and manages their lifecycle
- **CMDB Integration**: Database as a Service (DBAAS) for external database management

### Directory Structure

```
├── deploy/                    # Raw Kubernetes manifests
│   ├── crd.yaml              # Custom Resource Definition
│   ├── cr.yaml               # Example MistralService
│   ├── operator.yaml         # Operator deployment
│   └── rbac files...         # Security and permissions
├── deployments/charts/       # Helm chart
│   └── mistral-operator/
│       ├── Chart.yaml        # Chart metadata
│       ├── values.yaml       # Default configuration
│       ├── templates/        # Kubernetes manifest templates
│       └── crds/            # CRD files
├── src/                      # Operator source code
├── docs/                     # Documentation
└── build/                    # Build scripts
```

## Deployment Options

### Option 1: Direct Manifests
```bash
kubectl apply -f deploy/crd.yaml
kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/role.yaml
kubectl apply -f deploy/role_binding.yaml
kubectl apply -f deploy/operator.yaml
kubectl apply -f deploy/cr.yaml
```

### Option 2: Helm Chart
```bash
helm install mistral-operator deployments/charts/mistral-operator/
```

### Option 3: Helm Template + kubectl
```bash
helm template mistral-operator deployments/charts/mistral-operator/ | kubectl apply -f -
```

## How It Works

1. **CRD Registration**: Custom Resource Definition creates new API type `MistralService`
2. **Operator Deployment**: Operator pod watches for MistralService resources
3. **Resource Creation**: When MistralService is created, operator deploys:
   - mistral-api (REST API service)
   - mistral-engine (workflow execution engine)
   - mistral-executor (task executor)
   - mistral-monitoring (health monitoring)
   - mistral-notifier (event notifications)
4. **Lifecycle Management**: Operator handles updates, scaling, and cleanup

## Configuration

### Minimal Configuration
```yaml
apiVersion: qubership.org/v1
kind: MistralService
metadata:
  name: mistral-service
spec:
  mistral:
    dockerImage: "ghcr.io/netcracker/qubership-mistral"
  mistralCommonParams:
    postgres:
      host: "my-postgres"
      dbName: "mistraldb"
    rabbit:
      host: "my-rabbitmq"
```

### Production Configuration
- Use Helm values.yaml for complex configurations
- Set resource limits and requests for each component
- Configure external dependencies (PostgreSQL, RabbitMQ)
- Enable TLS and authentication
- Set up monitoring and alerting

## Dependencies

Mistral requires external services:
- **PostgreSQL**: Database for workflow definitions and execution state
- **RabbitMQ**: Message queue for task distribution
- **Certificate Store**: For secure communications (optional)
- **Zipkin**: Distributed tracing (optional)

## Monitoring and Troubleshooting

### Check Operator Status
```bash
kubectl get pods -l name=mistral-operator
kubectl logs -l name=mistral-operator
```

### Check MistralService Status
```bash
kubectl get mistralservice
kubectl describe mistralservice mistral-service
```

### Check Mistral Components
```bash
kubectl get pods -l app.kubernetes.io/name=mistral
kubectl logs -l app.kubernetes.io/name=mistral-api
```

## Documentation Links

- [Detailed Concepts and Deployment (English)](/docs/public/concepts-and-deployment.md)
- [Концепции и процесс развертывания (Русский)](/docs/public/concepts-and-deployment-ru.md)
- [Installation Guide](/docs/public/installation.md)
- [Architecture Guide](/docs/public/architecture.md)
- [Troubleshooting Guide](/docs/public/troubleshooting.md)

## Development

### Building the Operator
```bash
docker build -f Dockerfile -t mistral-operator:latest .
```

### Testing Helm Charts
```bash
helm template mistral-operator deployments/charts/mistral-operator/ --dry-run
helm lint deployments/charts/mistral-operator/
```

This guide provides a complete overview of the Mistral Operator and its deployment process in Kubernetes environments.