#!/bin/bash
# Скрипт установки Vault

# Создание namespace
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

# Добавление репозитория Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Установка Vault
helm install vault hashicorp/vault \
  --namespace vault \
  --values vault-values.yaml \
  --wait

echo "Vault установлен. Проверка статуса:"
kubectl get pods -n vault
