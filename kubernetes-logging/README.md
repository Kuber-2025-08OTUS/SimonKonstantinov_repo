# Kubernetes Logging Домашнее задание

## Установленные компоненты:
- **Loki** - сбор и хранение логов в S3
- **Promtail** - сбор логов со всех нод кластера
- **Grafana** - визуализация логов

## Архитектура:
- Loki и Grafana установлены на infra-ноде с taint `node-role=infra:NoSchedule`
- Promtail развернут как DaemonSet на всех нодах
- Логи хранятся в S3 бакете `loki-logs-konstsima`

## Файлы конфигурации:
- `loki-config.yaml` - конфигурация Loki
- `loki-deployment.yaml` - развертывание Loki
- `loki-service.yaml` - сервис Loki
- `promtail-config.yaml` - конфигурация Promtail
- `promtail-daemonset.yaml` - DaemonSet Promtail
- `grafana-config.yaml` - конфигурация Grafana
- `grafana-deployment.yaml` - развертывание Grafana
- `grafana-service.yaml` - сервис Grafana

## Файлы с выводами команд:
- `nodes-labels.txt` - вывод `kubectl get nodes -o wide --show-labels`
- `nodes-taints.txt` - вывод `kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints`
- `pods-status.txt` - вывод `kubectl get pods -n logging -o wide`
- `services-status.txt` - вывод `kubectl get svc -n logging`
- `daemonset-status.txt` - вывод `kubectl get daemonset -n logging`
- `cluster-info.txt` - объединенная информация о кластере


## Команды установки:
```bash
kubectl create namespace logging

# Создание секрета для S3 (ЗАМЕНИТЕ НА СВОИ КЛЮЧИ)
kubectl create secret generic loki-s3-credentials \
  --namespace=logging \
  --from-literal=access_key_id=<YOUR_ACCESS_KEY_ID> \
  --from-literal=access_key_secret=<YOUR_SECRET_ACCESS_KEY>

# Установка компонентов
kubectl apply -f loki-config.yaml
kubectl apply -f loki-deployment.yaml
kubectl apply -f loki-service.yaml
kubectl apply -f promtail-config.yaml
kubectl apply -f promtail-daemonset.yaml
kubectl apply -f grafana-config.yaml
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
Проверка работы:
bash
kubectl get pods -n logging -o wide
kubectl get svc -n logging

# Доступ к Grafana через port-forward
kubectl port-forward -n logging svc/grafana 3000:3000
