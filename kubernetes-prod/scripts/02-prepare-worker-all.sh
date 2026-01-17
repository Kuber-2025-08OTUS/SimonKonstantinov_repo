#!/bin/bash
# Все команды для подготовки worker-ноды одной командой

set -e

echo "=== Подготовка worker-ноды ==="

# 1. Отключение swap
echo "1. Отключение swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Включение маршрутизации
echo "2. Включение маршрутизации..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 3. Настройка параметров ядра
echo "3. Настройка параметров ядра..."
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# 4. Установка containerd
echo "4. Установка containerd..."
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

# Добавление GPG ключа Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавление репозитория Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка containerd
apt-get update
apt-get install -y containerd.io

# Настройка containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Перезапуск и включение containerd
systemctl restart containerd
systemctl enable containerd

# 5. Установка kubeadm, kubelet, kubectl
echo "5. Установка kubeadm, kubelet, kubectl..."
apt-get install -y apt-transport-https ca-certificates curl gpg

# Добавление GPG ключа Kubernetes
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Добавление репозитория Kubernetes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# Установка компонентов
apt-get update
apt-get install -y kubelet kubeadm kubectl

# Фиксация версий (предотвращение автоматического обновления)
apt-mark hold kubelet kubeadm kubectl

# 6. Проверка установки
echo "6. Проверка установки..."
echo "---"
kubeadm version
kubectl version --client
kubelet --version
containerd --version
echo "---"

echo ""
echo "=== Подготовка worker-ноды завершена ==="
echo "Теперь можно выполнить команду kubeadm join на этой ноде"
