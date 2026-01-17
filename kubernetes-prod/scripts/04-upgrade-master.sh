#!/bin/bash
# Скрипт для обновления master-ноды до последней версии Kubernetes
# Текущая версия: v1.34.x → Целевая версия: v1.35.0
# Выполните этот скрипт на master-ноде

set -e

TARGET_VERSION="1.35"
TARGET_FULL_VERSION="v1.35.0"

echo "=== Обновление master-ноды до версии ${TARGET_FULL_VERSION} ==="

# 1. Обновление kubeadm до версии 1.35
echo "1. Обновление kubeadm до версии ${TARGET_VERSION}..."
sudo apt-mark unhold kubeadm
sudo apt-get update

# Добавление репозитория Kubernetes для версии 1.35
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${TARGET_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${TARGET_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# Проверка доступных версий kubeadm
echo "Проверка доступных версий kubeadm ${TARGET_VERSION}..."
KUBEADM_VERSION=$(apt-cache madison kubeadm | grep ${TARGET_VERSION} | head -1 | awk '{print $3}')

if [ -z "$KUBEADM_VERSION" ]; then
  echo "ОШИБКА: Версия ${TARGET_VERSION} не найдена для kubeadm!"
  echo "Доступные версии:"
  apt-cache madison kubeadm | head -10
  exit 1
fi

echo "Установка kubeadm версии: $KUBEADM_VERSION"
sudo apt-get install -y kubeadm=$KUBEADM_VERSION
sudo apt-mark hold kubeadm

# Проверка версии kubeadm
kubeadm version

# 2. Просмотр плана обновления
echo ""
echo "2. Просмотр плана обновления..."
sudo kubeadm upgrade plan

# 3. Применение обновления master-ноды
echo ""
echo "3. Применение обновления до ${TARGET_FULL_VERSION}..."
sudo kubeadm upgrade apply ${TARGET_FULL_VERSION} --yes

# 4. Обновление kubelet и kubectl до версии 1.35
echo ""
echo "4. Обновление kubelet и kubectl до версии ${TARGET_VERSION}..."
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

# 5. Перезагрузка конфигурации и перезапуск kubelet
echo ""
echo "5. Перезапуск kubelet..."
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 6. Проверка статуса
echo ""
echo "6. Проверка статуса кластера..."
sleep 5
kubectl get nodes -o wide

echo ""
echo "=== Обновление master-ноды завершено ==="
echo "Master-нода обновлена до версии ${TARGET_FULL_VERSION}"