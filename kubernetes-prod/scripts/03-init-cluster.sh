#!/bin/bash
# Скрипт для инициализации кластера Kubernetes на master-ноде
# Выполните этот скрипт на master-ноде после подготовки (01-prepare-master.md)

set -e

echo "=== Инициализация кластера Kubernetes ==="

# 1. Инициализация кластера с kubeadm
echo "1. Инициализация кластера с kubeadm..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# 2. Настройка kubectl для текущего пользователя
echo "2. Настройка kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 3. Установка Flannel (CNI плагин)
echo "3. Установка Flannel (CNI плагин)..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# 4. Ожидание готовности Flannel
echo "4. Ожидание готовности Flannel..."
sleep 10
kubectl wait --for=condition=Ready pods --all -n kube-flannel --timeout=300s || true

# 5. Получение команды для присоединения worker-нод
echo ""
echo "=== Команда для присоединения worker-нод ==="
echo "Выполните следующую команду на каждой worker-ноде:"
kubeadm token create --print-join-command

# 6. Проверка статуса кластера
echo ""
echo "=== Статус кластера ==="
kubectl get nodes -o wide

echo ""
echo "=== Инициализация кластера завершена ==="
echo "Сохраните вывод команды kubeadm join выше для присоединения worker-нод"