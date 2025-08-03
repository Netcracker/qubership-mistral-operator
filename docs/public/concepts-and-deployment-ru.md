# Концепции и процесс развертывания Mistral Operator

## Что такое CR (Custom Resource)

**Custom Resource (Пользовательский ресурс)** - это расширение API Kubernetes, которое позволяет создавать собственные типы ресурсов в дополнение к встроенным (Pod, Service, Deployment и т.д.).

### В контексте Mistral Operator:

1. **Определение CRD (Custom Resource Definition)**:
   - Файл `deploy/crd.yaml` и `deployments/charts/mistral-operator/crds/crd.yaml` определяют новый тип ресурса `MistralService`
   - Этот ресурс принадлежит группе API `qubership.org/v1`
   - Короткие имена: `mistral`, `mistrals`

2. **Пример CR (Custom Resource)**:
   - Файл `deploy/cr.yaml` содержит экземпляр `MistralService`
   - Описывает конфигурацию для развертывания Mistral со всеми компонентами:
     - mistral-api (API сервис)
     - mistral-engine (движок выполнения)
     - mistral-executor (исполнитель задач)
     - mistral-monitoring (мониторинг)
     - mistral-notifier (уведомления)

3. **Как это работает**:
   ```yaml
   apiVersion: qubership.org/v1
   kind: MistralService
   metadata:
     name: mistral-service
   spec:
     mistral:
       dockerImage: "ghcr.io/netcracker/qubership-mistral"
     # ... остальная конфигурация
   ```

## Что такое Helm

**Helm** - это пакетный менеджер для Kubernetes, который упрощает развертывание и управление приложениями.

### Основные концепции:

1. **Chart (Чарт)** - пакет, содержащий шаблоны Kubernetes манифестов
2. **Templates (Шаблоны)** - файлы YAML с переменными, которые заполняются значениями
3. **Values (Значения)** - конфигурационные параметры для шаблонов

### В нашем проекте:

```
deployments/charts/mistral-operator/
├── Chart.yaml              # Метаданные чарта
├── values.yaml             # Значения по умолчанию
├── crds/
│   └── crd.yaml            # CRD определения
└── templates/
    ├── deployment.yaml     # Шаблон развертывания оператора
    ├── service_account.yaml # Шаблон сервисного аккаунта
    ├── role.yaml           # Шаблон роли RBAC
    ├── cr.yaml             # Шаблон пользовательского ресурса
    └── ...
```

## Что такое helm template

`helm template` - команда, которая обрабатывает шаблоны Helm и генерирует итоговые YAML манифесты без их применения к кластеру.

### Использование:

```bash
# Генерация манифестов из чарта
helm template mistral-operator deployments/charts/mistral-operator/

# С кастомными значениями
helm template mistral-operator deployments/charts/mistral-operator/ \
  --values custom-values.yaml

# Сохранение в файл
helm template mistral-operator deployments/charts/mistral-operator/ \
  > generated-manifests.yaml
```

### Преимущества:
- Просмотр итоговых манифестов перед применением
- Отладка шаблонов
- Интеграция с CI/CD пайплайнами
- Версионирование сгенерированных манифестов

## Процесс сборки и развертывания

### 1. Сборка Docker образа

```bash
# Из директории build/
docker build -f ../Dockerfile -t mistral-operator:latest .
```

### 2. Подготовка манифестов

**Вариант A: Прямые манифесты**
```bash
# Применение CRD
kubectl apply -f deploy/crd.yaml

# Применение RBAC
kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/role.yaml
kubectl apply -f deploy/role_binding.yaml

# Развертывание оператора
kubectl apply -f deploy/operator.yaml

# Создание экземпляра MistralService
kubectl apply -f deploy/cr.yaml
```

**Вариант B: Helm**
```bash
# Установка через Helm
helm install mistral-operator deployments/charts/mistral-operator/

# Или генерация и применение
helm template mistral-operator deployments/charts/mistral-operator/ | kubectl apply -f -
```

### 3. Процесс работы оператора

1. **Инициализация**: Оператор запускается и регистрирует обработчики для `MistralService`
2. **Мониторинг**: Отслеживает создание/изменение/удаление ресурсов `MistralService`
3. **Reconciliation**: При изменениях создает/обновляет соответствующие Kubernetes ресурсы:
   - Deployments для каждого компонента Mistral
   - Services для сетевого доступа
   - ConfigMaps для конфигурации
   - Secrets для секретных данных

## Что такое CMDB

**CMDB (Configuration Management Database)** - база данных управления конфигурациями, которая содержит информацию о IT-инфраструктуре и связях между компонентами.

### В контексте Mistral:

В файле `deploy/cr.yaml` есть ссылка на DBAAS (Database as a Service):
```yaml
dbaas:
  agentUrl: 'http://dbaas-agent:8080'
  aggregatorUrl: ''
```

Это указывает на интеграцию с системой управления базами данных, которая может включать:
- Автоматическое создание БД
- Мониторинг состояния
- Резервное копирование
- Масштабирование

## Папка deploy: содержимое и назначение

### Структура:

```
deploy/
├── crd.yaml              # Custom Resource Definition
├── cr.yaml               # Пример Custom Resource
├── operator.yaml         # Развертывание самого оператора
├── role.yaml            # RBAC роль с правами
├── role_binding.yaml    # Привязка роли к сервисному аккаунту
├── service_account.yaml # Сервисный аккаунт для оператора
└── rabbit_roles.yaml   # Настройки для RabbitMQ
```

### Назначение каждого файла:

1. **crd.yaml** - Определяет новый тип ресурса `MistralService` в Kubernetes API
2. **service_account.yaml** - Создает сервисный аккаунт для работы оператора
3. **role.yaml** - Определяет права доступа к ресурсам Kubernetes
4. **role_binding.yaml** - Связывает роль с сервисным аккаунтом
5. **operator.yaml** - Deployment для самого оператора
6. **cr.yaml** - Пример конфигурации Mistral сервиса
7. **rabbit_roles.yaml** - Настройки ролей для RabbitMQ

### Последствия и принципы:

- **Безопасность**: RBAC обеспечивает минимальные необходимые права
- **Расширяемость**: CRD позволяет описывать сложные конфигурации декларативно
- **Автоматизация**: Оператор автоматически управляет жизненным циклом
- **Версионирование**: Все манифесты в Git для отслеживания изменений

## Развертывание в Kubernetes: полный процесс

### Архитектура развертывания:

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

### Пошаговый процесс:

1. **Подготовка кластера**:
   ```bash
   # Применение CRD
   kubectl apply -f deploy/crd.yaml
   ```

2. **Настройка RBAC**:
   ```bash
   kubectl apply -f deploy/service_account.yaml
   kubectl apply -f deploy/role.yaml
   kubectl apply -f deploy/role_binding.yaml
   ```

3. **Развертывание оператора**:
   ```bash
   kubectl apply -f deploy/operator.yaml
   ```

4. **Создание экземпляра Mistral**:
   ```bash
   kubectl apply -f deploy/cr.yaml
   ```

5. **Проверка развертывания**:
   ```bash
   # Проверка статуса оператора
   kubectl get pods -l app=mistral-operator
   
   # Проверка MistralService
   kubectl get mistralservice
   
   # Проверка компонентов Mistral
   kubectl get pods -l app.kubernetes.io/name=mistral
   ```

### Альтернативный способ через Helm:

```bash
# Одной командой
helm install mistral-operator deployments/charts/mistral-operator/

# С кастомными значениями
helm install mistral-operator deployments/charts/mistral-operator/ \
  --values my-values.yaml

# Обновление
helm upgrade mistral-operator deployments/charts/mistral-operator/
```

### Мониторинг и отладка:

```bash
# Логи оператора
kubectl logs -l app=mistral-operator

# События
kubectl get events

# Описание ресурса
kubectl describe mistralservice mistral-service

# Логи компонентов Mistral
kubectl logs -l app.kubernetes.io/name=mistral-api
```

## Практические примеры

### Пример 1: Быстрое развертывание через Helm

```bash
# Клонирование репозитория
git clone https://github.com/Netcracker/qubership-mistral-operator.git
cd qubership-mistral-operator

# Развертывание оператора и создание MistralService
helm install mistral-operator deployments/charts/mistral-operator/ \
  --set mistralCommonParams.postgres.host=my-postgres.default \
  --set mistralCommonParams.rabbit.host=my-rabbitmq.default

# Проверка статуса
kubectl get mistralservice
kubectl get pods -l app.kubernetes.io/name=mistral
```

### Пример 2: Кастомизация через values.yaml

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

### Пример 3: Генерация манифестов для CI/CD

```bash
# Генерация всех манифестов
helm template mistral-operator deployments/charts/mistral-operator/ \
  --values production-values.yaml \
  --output-dir ./generated-manifests

# Применение через kubectl
kubectl apply -R -f ./generated-manifests/
```

### Пример 4: Отладка и мониторинг

```bash
# Просмотр событий
kubectl get events --sort-by=.metadata.creationTimestamp

# Логи оператора
kubectl logs -l name=mistral-operator -f

# Статус MistralService
kubectl describe mistralservice mistral-service

# Логи компонентов Mistral
kubectl logs -l app.kubernetes.io/name=mistral-api
kubectl logs -l app.kubernetes.io/name=mistral-engine
```

Этот документ предоставляет полное понимание всех компонентов и процессов развертывания Mistral Operator в Kubernetes.