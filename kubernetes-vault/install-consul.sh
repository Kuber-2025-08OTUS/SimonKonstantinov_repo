#!/bin/bash
# Скрипт установки Consul

# Создание namespace
kubectl create namespace consul --dry-run=client -o yaml | kubectl apply -f -

# Добавление репозитория Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Установка Consul
helm install consul hashicorp/consul \
  --namespace consul \
  --values consul-values.yaml \
  --wait

echo "Consul установлен. Проверка статуса:"
kubectl get pods -n consul
