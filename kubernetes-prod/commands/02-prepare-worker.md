# Команды для подготовки worker-нод

Выполняйте команды последовательно на каждой worker-ноде с правами root или через sudo.

## 1. Отключение swap

```bash
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

## 2. Включение маршрутизации

```bash
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
```

## 3. Настройка параметров ядра

```bash
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
```

## 4. Установка containerd

```bash
# Обновление пакетов
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
```

## 5. Установка kubeadm, kubelet, kubectl

**ВАЖНО:** Используйте ту же версию, что и на master-ноде (на одну ниже актуальной).

```bash
# Установка необходимых пакетов
apt-get install -y apt-transport-https ca-certificates curl gpg

# Добавление GPG ключа Kubernetes
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Добавление репозитория Kubernetes
# ВАЖНО: Замените v1.34 на нужную версию (должна совпадать с master-нодой)
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# Установка компонентов
apt-get update
apt-get install -y kubelet kubeadm kubectl

# Фиксация версий (предотвращение автоматического обновления)
apt-mark hold kubelet kubeadm kubectl
```

## Проверка установки

```bash
kubeadm version
kubectl version --client
kubelet --version
containerd --version
```

## Все команды одной строкой (для копирования)

```bash
swapoff -a && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && cat <<'EOFK8S' | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOFK8S
modprobe overlay && modprobe br_netfilter && cat <<'EOFK8S' | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOFK8S
sysctl --system && apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release && mkdir -p /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && apt-get update && apt-get install -y containerd.io && mkdir -p /etc/containerd && containerd config default | tee /etc/containerd/config.toml && sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml && systemctl restart containerd && systemctl enable containerd && apt-get install -y apt-transport-https ca-certificates curl gpg && mkdir -p /etc/apt/keyrings && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list && apt-get update && apt-get install -y kubelet kubeadm kubectl && apt-mark hold kubelet kubeadm kubectl && kubeadm version && kubectl version --client && kubelet --version && containerd --version
```
