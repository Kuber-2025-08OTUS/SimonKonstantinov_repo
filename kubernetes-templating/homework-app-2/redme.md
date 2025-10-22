# Задание 2: Kafka Deployments через Helmfile

## Описание

Развертывание двух Kafka кластеров с разными конфигурациями в пространствах имён prod и dev, используя Helmfile для управления Helm релизами.

## Требования

### PROD кластер (namespace: prod)
- 5 брокеров Kafka
- Версия: 3.5.1
- Протокол: SASL_PLAINTEXT (для client и interbroker взаимодействия)
- Авторизация: включена (admin user)

### DEV кластер (namespace: dev)
- 1 брокер Kafka
- Версия: 3.8.0 (latest)
- Протокол: PLAINTEXT (для client и interbroker взаимодействия)
- Авторизация: отключена

## Структура файлов

```
├── helmfile.yaml                  # Конфигурация helmfile с двумя релизами
├── kafka-prod-values.yaml         # Values для production (5 brokers, SASL_PLAINTEXT)
├── kafka-dev-values.yaml          # Values для development (1 broker, PLAINTEXT)
└── README.md                       # Этот файл
```

## Установка

### Развертывание через helmfile

```bash
helmfile sync
```

## Проверка

### Проверить установленные релизы

```bash
helm list -A | grep kafka
```

### Проверить поды в PROD

```bash
kubectl -n prod get pods -l app.kubernetes.io/name=kafka
```

Ожидается 5 brokers + controllers

### Проверить поды в DEV

```bash
kubectl -n dev get pods -l app.kubernetes.io/name=kafka
```

Ожидается 1 broker + controllers

## Конфигурация PROD

| Параметр | Значение |
|----------|----------|
| Namespace | prod |
| Brokers | 5 |
| Kafka версия | 3.5.1 |
| Client Protocol | SASL_PLAINTEXT |
| Interbroker Protocol | SASL_PLAINTEXT |
| Authentication | Enabled |
| Username | admin |

## Конфигурация DEV

| Параметр | Значение |
|----------|----------|
| Namespace | dev |
| Brokers | 1 |
| Kafka версия | 3.8.0 (latest) |
| Client Protocol | PLAINTEXT |
| Interbroker Protocol | PLAINTEXT |
| Authentication | Disabled |

## Удаление

```bash
helmfile destroy
```

## Ссылки

- [Bitnami Kafka Chart](https://github.com/bitnami/charts/tree/main/bitnami/kafka)
- [Helmfile Documentation](https://github.com/helmfile/helmfile)

