#!/bin/bash
# Скрипт для настройки kubectl после развертывания кластера
# Выполнять на ВМ k8s-learning-vm

set -e

echo "=== Настройка kubectl для подключения к HA-кластеру ==="
echo ""

# 1. Создание директории для kubeconfig
echo "1. Создание директории ~/.kube..."
mkdir -p ~/.kube

# 2. Копирование kubeconfig с первой master-ноды
echo "2. Копирование kubeconfig с k8s-ha-master-1 (10.129.0.11)..."
scp -i /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key \
    root@10.129.0.11:/etc/kubernetes/admin.conf \
    ~/.kube/config

# 3. Установка правильных прав доступа
echo "3. Установка прав доступа на ~/.kube/config..."
chmod 600 ~/.kube/config

# 4. Проверка подключения
echo ""
echo "4. Проверка подключения к кластеру..."
echo "=== kubectl cluster-info ==="
kubectl cluster-info

echo ""
echo "5. Проверка статуса нод..."
echo "=== kubectl get nodes -o wide ==="
kubectl get nodes -o wide

echo ""
echo "✅ kubectl настроен успешно!"
echo ""
echo "Следующие шаги:"
echo "1. Сохранить inventory файл: cp /tmp/kubespray/inventory/ha-cluster/hosts.yaml ~/SimonKonstantinov_repo/kubernetes-prod/kubespray/inventory.ini"
echo "2. Сохранить вывод: kubectl get nodes -o wide > ~/SimonKonstantinov_repo/kubernetes-prod/outputs/kubespray-nodes.txt"
