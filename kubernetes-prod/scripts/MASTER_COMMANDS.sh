#!/bin/bash
# Команды для выполнения на master-ноде (k8s-master)
# Скопируйте и выполните эти команды на master-ноде

set -e

echo "=== Подготовка master-ноды Kubernetes ==="

# 1. Отключение swap
echo "1. Отключение swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Включение маршрутизации
echo "2. Включение маршрутизации..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 3. Настройка параметров ядра
echo "3. Настройка параметров ядра..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 4. Установка containerd
echo "4. Установка containerd..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

# Настройка containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# 5. Установка kubeadm, kubelet, kubectl
echo "5. Установка kubeadm, kubelet, kubectl..."
# ВАЖНО: Версия Kubernetes должна быть на одну ниже актуальной
# Актуальная версия: v1.35.0, поэтому используем v1.34.x
K8S_VERSION="1.34"

# Удаление старых репозиториев (если есть)
sudo rm -f /etc/apt/sources.list.d/kubernetes.list
sudo rm -f /etc/apt/sources.list.d/hashicorp.list

sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Добавление нового репозитория Kubernetes
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 6. Проверка установки
echo "6. Проверка установки..."
kubeadm version
kubectl version --client
kubelet --version
containerd --version

echo ""
echo "=== Подготовка master-ноды завершена ==="
echo "Следующий шаг: выполните kubeadm init (см. commands/03-init-cluster.md)"
