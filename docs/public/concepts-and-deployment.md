# Mistral Operator Concepts and Deployment Process

## What is CR (Custom Resource)

**Custom Resource** is a Kubernetes API extension that allows you to create your own resource types in addition to built-in ones (Pod, Service, Deployment, etc.).

### In Mistral Operator context:

1. **CRD (Custom Resource Definition)**:
   - Files `deploy/crd.yaml` and `deployments/charts/mistral-operator/crds/crd.yaml` define a new resource type `MistralService`
   - This resource belongs to API group `qubership.org/v1`
   - Short names: `mistral`, `mistrals`

2. **CR (Custom Resource) example**:
   - File `deploy/cr.yaml` contains an instance of `MistralService`
   - Describes configuration for deploying Mistral with all components:
     - mistral-api (API service)
     - mistral-engine (execution engine)
     - mistral-executor (task executor)
     - mistral-monitoring (monitoring)
     - mistral-notifier (notifications)

3. **How it works**:
   ```yaml
   apiVersion: qubership.org/v1
   kind: MistralService
   metadata:
     name: mistral-service
   spec:
     mistral:
       dockerImage: "ghcr.io/netcracker/qubership-mistral"
     # ... rest of configuration
   ```

## What is Helm

**Helm** is a package manager for Kubernetes that simplifies application deployment and management.

### Core concepts:

1. **Chart** - a package containing Kubernetes manifest templates
2. **Templates** - YAML files with variables that are filled with values
3. **Values** - configuration parameters for templates

### In our project:

```
deployments/charts/mistral-operator/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── crds/
│   └── crd.yaml            # CRD definitions
└── templates/
    ├── deployment.yaml     # Operator deployment template
    ├── service_account.yaml # Service account template
    ├── role.yaml           # RBAC role template
    ├── cr.yaml             # Custom resource template
    └── ...
```

## What is helm template

`helm template` is a command that processes Helm templates and generates final YAML manifests without applying them to the cluster.

### Usage:

```bash
# Generate manifests from chart
helm template mistral-operator deployments/charts/mistral-operator/

# With custom values
helm template mistral-operator deployments/charts/mistral-operator/ \
  --values custom-values.yaml

# Save to file
helm template mistral-operator deployments/charts/mistral-operator/ \
  > generated-manifests.yaml
```

### Benefits:
- Preview final manifests before applying
- Template debugging
- CI/CD pipeline integration
- Generated manifest versioning

## Build and Deployment Process

### 1. Docker Image Build

```bash
# From build/ directory
docker build -f ../Dockerfile -t mistral-operator:latest .
```

### 2. Manifest Preparation

**Option A: Direct manifests**
```bash
# Apply CRD
kubectl apply -f deploy/crd.yaml

# Apply RBAC
kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/role.yaml
kubectl apply -f deploy/role_binding.yaml

# Deploy operator
kubectl apply -f deploy/operator.yaml

# Create MistralService instance
kubectl apply -f deploy/cr.yaml
```

**Option B: Helm**
```bash
# Install via Helm
helm install mistral-operator deployments/charts/mistral-operator/

# Or generate and apply
helm template mistral-operator deployments/charts/mistral-operator/ | kubectl apply -f -
```

### 3. Operator Workflow

1. **Initialization**: Operator starts and registers handlers for `MistralService`
2. **Monitoring**: Watches for creation/modification/deletion of `MistralService` resources
3. **Reconciliation**: On changes, creates/updates corresponding Kubernetes resources:
   - Deployments for each Mistral component
   - Services for network access
   - ConfigMaps for configuration
   - Secrets for sensitive data

## What is CMDB

**CMDB (Configuration Management Database)** is a database containing information about IT infrastructure and relationships between components.

### In Mistral context:

In `deploy/cr.yaml` there's a reference to DBAAS (Database as a Service):
```yaml
dbaas:
  agentUrl: 'http://dbaas-agent:8080'
  aggregatorUrl: ''
```

This indicates integration with a database management system that may include:
- Automatic database creation
- State monitoring
- Backup management
- Scaling

## Deploy Folder: Contents and Purpose

### Structure:

```
deploy/
├── crd.yaml              # Custom Resource Definition
├── cr.yaml               # Example Custom Resource
├── operator.yaml         # Operator deployment
├── role.yaml            # RBAC role with permissions
├── role_binding.yaml    # Role binding to service account
├── service_account.yaml # Service account for operator
└── rabbit_roles.yaml   # RabbitMQ role settings
```

### Purpose of each file:

1. **crd.yaml** - Defines new resource type `MistralService` in Kubernetes API
2. **service_account.yaml** - Creates service account for operator
3. **role.yaml** - Defines Kubernetes resource access permissions
4. **role_binding.yaml** - Links role to service account
5. **operator.yaml** - Deployment for the operator itself
6. **cr.yaml** - Example Mistral service configuration
7. **rabbit_roles.yaml** - RabbitMQ role settings

### Consequences and principles:

- **Security**: RBAC ensures minimal necessary permissions
- **Extensibility**: CRD allows describing complex configurations declaratively
- **Automation**: Operator automatically manages lifecycle
- **Versioning**: All manifests in Git for change tracking

## Kubernetes Deployment: Complete Process

### Deployment Architecture:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   kubectl/Helm  │───▶│  Kubernetes API  │───▶│ Mistral Operator│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Mistral Components                               │
├─────────────────┬─────────────────┬─────────────────┬──────────────┤
│  mistral-api    │ mistral-engine  │ mistral-executor│ mistral-...  │
├─────────────────┼─────────────────┼─────────────────┼──────────────┤
│   Deployment    │   Deployment    │   Deployment    │ Deployment   │
│   Service       │   Service       │   Service       │ Service      │
│   ConfigMap     │   ConfigMap     │   ConfigMap     │ ConfigMap    │
└─────────────────┴─────────────────┴─────────────────┴──────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   External Dependencies                            │
├─────────────────┬─────────────────┬─────────────────┬──────────────┤
│   PostgreSQL    │   RabbitMQ      │  Certificate    │   Zipkin     │
│   Database      │   Message Bus   │     Store       │   Tracing    │
└─────────────────┴─────────────────┴─────────────────┴──────────────┘
```

### Step-by-step process:

1. **Cluster preparation**:
   ```bash
   # Apply CRD
   kubectl apply -f deploy/crd.yaml
   ```

2. **RBAC setup**:
   ```bash
   kubectl apply -f deploy/service_account.yaml
   kubectl apply -f deploy/role.yaml
   kubectl apply -f deploy/role_binding.yaml
   ```

3. **Operator deployment**:
   ```bash
   kubectl apply -f deploy/operator.yaml
   ```

4. **Mistral instance creation**:
   ```bash
   kubectl apply -f deploy/cr.yaml
   ```

5. **Deployment verification**:
   ```bash
   # Check operator status
   kubectl get pods -l app=mistral-operator
   
   # Check MistralService
   kubectl get mistralservice
   
   # Check Mistral components
   kubectl get pods -l app.kubernetes.io/name=mistral
   ```

### Alternative Helm approach:

```bash
# Single command
helm install mistral-operator deployments/charts/mistral-operator/

# With custom values
helm install mistral-operator deployments/charts/mistral-operator/ \
  --values my-values.yaml

# Upgrade
helm upgrade mistral-operator deployments/charts/mistral-operator/
```

### Monitoring and debugging:

```bash
# Operator logs
kubectl logs -l app=mistral-operator

# Events
kubectl get events

# Resource description
kubectl describe mistralservice mistral-service

# Mistral component logs
kubectl logs -l app.kubernetes.io/name=mistral-api
```

## Practical Examples

### Example 1: Quick deployment via Helm

```bash
# Clone repository
git clone https://github.com/Netcracker/qubership-mistral-operator.git
cd qubership-mistral-operator

# Deploy operator and create MistralService
helm install mistral-operator deployments/charts/mistral-operator/ \
  --set mistralCommonParams.postgres.host=my-postgres.default \
  --set mistralCommonParams.rabbit.host=my-rabbitmq.default

# Check status
kubectl get mistralservice
kubectl get pods -l app.kubernetes.io/name=mistral
```

### Example 2: Customization via values.yaml

```yaml
# custom-values.yaml
mistral:
  dockerImage: "my-registry.com/mistral:v1.2.3"

mistralApi:
  replicas: 3
  resources:
    requests:
      cpu: 500m
      memory: 1Gi

mistralCommonParams:
  postgres:
    host: "production-postgres.database"
    dbName: "mistral_prod"
  multitenancyEnabled: 'True'
```

```bash
helm install mistral-operator deployments/charts/mistral-operator/ \
  --values custom-values.yaml
```

### Example 3: Generating manifests for CI/CD

```bash
# Generate all manifests
helm template mistral-operator deployments/charts/mistral-operator/ \
  --values production-values.yaml \
  --output-dir ./generated-manifests

# Apply via kubectl
kubectl apply -R -f ./generated-manifests/
```

### Example 4: Debugging and monitoring

```bash
# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Operator logs
kubectl logs -l name=mistral-operator -f

# MistralService status
kubectl describe mistralservice mistral-service

# Mistral component logs
kubectl logs -l app.kubernetes.io/name=mistral-api
kubectl logs -l app.kubernetes.io/name=mistral-engine
```

This document provides complete understanding of all components and deployment processes for Mistral Operator in Kubernetes.