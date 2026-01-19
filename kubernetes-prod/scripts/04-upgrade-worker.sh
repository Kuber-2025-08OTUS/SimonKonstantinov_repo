#!/bin/bash
# Скрипт для обновления worker-ноды до последней версии Kubernetes
# Текущая версия: v1.34.x → Целевая версия: v1.35.0
# 
# ВАЖНО: Перед выполнением этого скрипта на worker-ноде:
# 1. На master-ноде выполните: kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
# 2. Выполните этот скрипт на worker-ноде
# 3. После завершения на master-ноде выполните: kubectl uncordon <node-name>
#
# Использование: ./04-upgrade-worker.sh <node-name>
#   где <node-name> - имя worker-ноды (например, k8s-worker-1)

set -e

TARGET_VERSION="1.35"

if [ -z "$1" ]; then
  echo "ОШИБКА: Укажите имя ноды в качестве параметра"
  echo "Использование: $0 <node-name>"
  echo "Пример: $0 k8s-worker-1"
  exit 1
fi

NODE_NAME=$1

echo "=== Обновление worker-ноды ${NODE_NAME} до версии v${TARGET_VERSION}.0 ==="
echo "ВНИМАНИЕ: Убедитесь, что на master-ноде выполнена команда:"
echo "  kubectl drain ${NODE_NAME} --ignore-daemonsets --delete-emptydir-data"
echo ""
read -p "Продолжить? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 1
fi

# 1. Обновление kubeadm до версии 1.35
echo "1. Обновление kubeadm до версии ${TARGET_VERSION}..."
sudo apt-mark unhold kubeadm
sudo apt-get update

# Добавление репозитория Kubernetes для версии 1.35 (если еще не добавлен)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${TARGET_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${TARGET_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# Получение точной версии kubeadm
KUBEADM_VERSION=$(apt-cache madison kubeadm | grep ${TARGET_VERSION} | head -1 | awk '{print $3}')

if [ -z "$KUBEADM_VERSION" ]; then
  echo "ОШИБКА: Версия ${TARGET_VERSION} не найдена для kubeadm!"
  exit 1
fi

echo "Установка kubeadm версии: $KUBEADM_VERSION"
sudo apt-get install -y kubeadm=$KUBEADM_VERSION
sudo apt-mark hold kubeadm

# 2. Обновление конфигурации ноды
echo ""
echo "2. Обновление конфигурации ноды..."
sudo kubeadm upgrade node

# 3. Обновление kubelet и kubectl до версии 1.35
echo ""
echo "3. Обновление kubelet и kubectl до версии ${TARGET_VERSION}..."
sudo apt-mark unhold kubelet kubectl
sudo apt-get update

# Получение точных версий
KUBELET_VERSION=$(apt-cache madison kubelet | grep ${TARGET_VERSION} | head -1 | awk '{print $3}')
KUBECTL_VERSION=$(apt-cache madison kubectl | grep ${TARGET_VERSION} | head -1 | awk '{print $3}')

if [ -z "$KUBELET_VERSION" ] || [ -z "$KUBECTL_VERSION" ]; then
  echo "ОШИБКА: Версии ${TARGET_VERSION} не найдены для kubelet или kubectl!"
  exit 1
fi

echo "Установка kubelet версии: $KUBELET_VERSION"
echo "Установка kubectl версии: $KUBECTL_VERSION"
sudo apt-get install -y kubelet=$KUBELET_VERSION kubectl=$KUBECTL_VERSION
sudo apt-mark hold kubelet kubectl

# 4. Перезагрузка конфигурации и перезапуск kubelet
echo ""
echo "4. Перезапуск kubelet..."
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 5. Проверка статуса kubelet
echo ""
echo "5. Проверка статуса kubelet..."
sleep 5
sudo systemctl status kubelet --no-pager

echo ""
echo "=== Обновление worker-ноды ${NODE_NAME} завершено ==="
echo "Теперь на master-ноде выполните: kubectl uncordon ${NODE_NAME}"