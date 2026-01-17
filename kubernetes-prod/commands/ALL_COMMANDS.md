# Все команды для развертывания и обновления кластера Kubernetes

Этот документ содержит все команды, выполненные для развертывания и обновления кластера Kubernetes, для возможности полного воспроизведения.

## Информация о кластере

- **Актуальная версия Kubernetes:** v1.35.0 (на момент выполнения задания)
- **Начальная версия для установки:** v1.34.x (на одну ниже актуальной)
- **Конфигурация ВМ:**
  - Master-нода: 1 узел, 2vCPU, 8GB RAM
  - Worker-ноды: 3 узла, по 2vCPU, 8GB RAM каждый

## Этап 1: Подготовка master-ноды

Все команды выполняются на master-ноде с правами root или через sudo.

### 1.1. Отключение swap

```bash
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### 1.2. Включение маршрутизации

```bash
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
```

### 1.3. Настройка параметров ядра

```bash
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
```

### 1.4. Установка containerd

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

### 1.5. Установка kubeadm, kubelet, kubectl (версия 1.34.x)

```bash
# Установка необходимых пакетов
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
```

### 1.6. Проверка установки на master-ноде

```bash
kubeadm version
kubectl version --client
kubelet --version
containerd --version
```

---

## Этап 2: Подготовка worker-нод

Все команды выполняются на **каждой** worker-ноде с правами root или через sudo.

Команды идентичны командам для master-ноды (этап 1):

### 2.1-2.5. Повторить команды из этапа 1.1-1.5

Используйте те же команды для:
- Отключения swap (1.1)
- Включения маршрутизации (1.2)
- Настройки параметров ядра (1.3)
- Установки containerd (1.4)
- Установки kubeadm, kubelet, kubectl версии 1.34.x (1.5)

### 2.6. Проверка установки на worker-ноде

```bash
kubeadm version
kubectl version --client
kubelet --version
containerd --version
```

---

## Этап 3: Инициализация кластера

### 3.1. Инициализация кластера на master-ноде

```bash
kubeadm init --pod-network-cidr=10.244.0.0/16
```

**Важно:** Сохраните вывод команды `kubeadm join` из результата выполнения этой команды.

### 3.2. Настройка kubectl на master-ноде

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 3.3. Установка Flannel (CNI плагин)

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### 3.4. Ожидание готовности Flannel

```bash
kubectl wait --for=condition=Ready pods --all -n kube-flannel --timeout=300s
```

### 3.5. Присоединение worker-нод

На **каждой** worker-ноде выполните команду `kubeadm join`:

```bash
# Актуальная команда join (после инициализации кластера):
kubeadm join 10.129.0.3:6443 --token i8yglu.rmfyl2eii4hg9qp1 \
    --discovery-token-ca-cert-hash sha256:584cb2940ffb2d8be6b6712c9bac205d3d3d2a85b7eb164b3dc8483df658d81b
```

**Выполнить на каждой worker-ноде:**
- k8s-worker-1 (158.160.90.73) - пользователь: node1
- k8s-worker-2 (158.160.77.22) - пользователь: node2
- k8s-worker-3 (158.160.73.156) - пользователь: node3

**Пример подключения и выполнения:**
```bash
# Подключение к worker-1
ssh -i k8s-key node1@158.160.90.73

# Выполнение команды join (с sudo)
sudo kubeadm join 10.129.0.3:6443 --token i8yglu.rmfyl2eii4hg9qp1 \
    --discovery-token-ca-cert-hash sha256:584cb2940ffb2d8be6b6712c9bac205d3d3d2a85b7eb164b3dc8483df658d81b
```

**Если токен истек**, создайте новый на master-ноде:

```bash
# На master-ноде:
kubeadm token create --print-join-command
```

Используйте новый вывод команды для присоединения worker-нод.

### 3.6. Проверка кластера

```bash
# На master-ноде:
kubectl get nodes -o wide
```

**Ожидаемый вывод:**
```
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-master     Ready    control-plane   Xm    v1.34.3   10.129.0.10   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
k8s-worker-1   Ready    <none>          Xm    v1.34.3   10.129.0.22   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
k8s-worker-2   Ready    <none>          Xm    v1.34.3   10.129.0.18   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
k8s-worker-3   Ready    <none>          Xm    v1.34.3   10.129.0.31   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
```

### 3.7. Сохранение статуса кластера до обновления

```bash
# На master-ноде:
kubectl get nodes -o wide > outputs/nodes-before-upgrade.txt
```

---

## Этап 4: Обновление кластера до версии v1.35.0

### 4.1. Обновление master-ноды

#### 4.1.1. Обновление kubeadm до версии 1.35

```bash
# На master-ноде:
sudo apt-mark unhold kubeadm
sudo apt-get update

# Добавление репозитория Kubernetes для версии 1.35
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# Проверка доступных версий
apt-cache madison kubeadm | grep 1.35

# Получение точной версии
KUBEADM_VERSION=$(apt-cache madison kubeadm | grep 1.35 | head -1 | awk '{print $3}')

# Установка новой версии kubeadm
sudo apt-get install -y kubeadm=$KUBEADM_VERSION
sudo apt-mark hold kubeadm

# Проверка версии
kubeadm version
```

#### 4.1.2. Просмотр плана обновления

```bash
# На master-ноде:
sudo kubeadm upgrade plan
```

#### 4.1.3. Применение обновления master-ноды

```bash
# На master-ноде:
sudo kubeadm upgrade apply v1.35.0 --yes
```

#### 4.1.4. Обновление kubelet и kubectl до версии 1.35

```bash
# На master-ноде:
sudo apt-mark unhold kubelet kubectl
sudo apt-get update

# Получение точных версий
KUBELET_VERSION=$(apt-cache madison kubelet | grep 1.35 | head -1 | awk '{print $3}')
KUBECTL_VERSION=$(apt-cache madison kubectl | grep 1.35 | head -1 | awk '{print $3}')

# Установка новых версий
sudo apt-get install -y kubelet=$KUBELET_VERSION kubectl=$KUBECTL_VERSION
sudo apt-mark hold kubelet kubectl

# Перезапуск kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

#### 4.1.5. Проверка обновления master-ноды

```bash
# На master-ноде:
kubectl get nodes -o wide
```

Master-нода должна показывать версию v1.35.0.

---

### 4.2. Обновление worker-нод (последовательно, по одной)

Для **каждой** worker-ноды выполните следующие шаги последовательно:

#### Шаг 1: Вывод ноды из планирования (на master-ноде)

```bash
# На master-ноде:
kubectl drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data
```

**Пример:**
```bash
kubectl drain k8s-worker-1 --ignore-daemonsets --delete-emptydir-data
```

#### Шаг 2: Обновление компонентов на worker-ноде

```bash
# На worker-ноде:
# 1. Обновление kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update

# Добавление репозитория Kubernetes для версии 1.35 (если еще не добавлен)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# Получение точной версии kubeadm
KUBEADM_VERSION=$(apt-cache madison kubeadm | grep 1.35 | head -1 | awk '{print $3}')

# Установка новой версии kubeadm
sudo apt-get install -y kubeadm=$KUBEADM_VERSION
sudo apt-mark hold kubeadm

# 2. Обновление конфигурации ноды
sudo kubeadm upgrade node

# 3. Обновление kubelet и kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update

# Получение точных версий
KUBELET_VERSION=$(apt-cache madison kubelet | grep 1.35 | head -1 | awk '{print $3}')
KUBECTL_VERSION=$(apt-cache madison kubectl | grep 1.35 | head -1 | awk '{print $3}')

# Установка новых версий
sudo apt-get install -y kubelet=$KUBELET_VERSION kubectl=$KUBECTL_VERSION
sudo apt-mark hold kubelet kubectl

# 4. Перезапуск kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

#### Шаг 3: Возврат ноды в планирование (на master-ноде)

```bash
# На master-ноде:
kubectl uncordon <NODE_NAME>
```

**Пример:**
```bash
kubectl uncordon k8s-worker-1
```

#### Повторите шаги 1-3 для каждой следующей worker-ноды

**Важно:** Обновляйте worker-ноды последовательно, не параллельно. После обновления каждой ноды проверяйте, что она в статусе Ready перед переходом к следующей.

---

### 4.3. Финальная проверка кластера

```bash
# На master-ноде:
kubectl get nodes -o wide
```

**Ожидаемый вывод после обновления всех нод:**
```
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-master     Ready    control-plane   Xh    v1.35.0   10.129.0.10   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
k8s-worker-1   Ready    <none>          Xh    v1.35.0   10.129.0.22   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
k8s-worker-2   Ready    <none>          Xh    v1.35.0   10.129.0.18   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
k8s-worker-3   Ready    <none>          Xh    v1.35.0   10.129.0.31   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
```

### 4.4. Сохранение статуса кластера после обновления

```bash
# На master-ноде:
kubectl get nodes -o wide > outputs/nodes-after-upgrade.txt
```

---

## Использование скриптов

Для удобства все команды также доступны в виде исполняемых скриптов:

1. **MASTER_COMMANDS.sh** - Подготовка master-ноды
2. **02-prepare-worker-all.sh** - Подготовка worker-ноды
3. **03-init-cluster.sh** - Инициализация кластера
4. **04-upgrade-master.sh** - Обновление master-ноды
5. **04-upgrade-worker.sh** - Обновление worker-ноды (требует параметр: имя ноды)

**Пример использования скриптов:**

**Примечание:** Скрипты находятся в папке `scripts/`, а не в `commands/`.

```bash
# На master-ноде:
./scripts/MASTER_COMMANDS.sh
./scripts/03-init-cluster.sh

# На worker-ноде:
./scripts/02-prepare-worker-all.sh

# После присоединения всех worker-нод, на master-ноде:
./scripts/04-upgrade-master.sh

# На каждой worker-ноде (после drain на master-ноде):
./scripts/04-upgrade-worker.sh k8s-worker-1
```

---

## Результаты выполнения

### Статус кластера до обновления

Файл: `outputs/nodes-before-upgrade.txt`

### Статус кластера после обновления

Файл: `outputs/nodes-after-upgrade.txt`

---

## Дополнительные полезные команды

### Проверка версий компонентов

```bash
# На любой ноде:
kubeadm version
kubectl version --client
kubelet --version
containerd --version
```

### Проверка статуса сервисов

```bash
# На любой ноде:
sudo systemctl status kubelet
sudo systemctl status containerd
```

### Проверка подов кластера

```bash
# На master-ноде:
kubectl get pods --all-namespaces
kubectl get pods -n kube-system
kubectl get pods -n kube-flannel
```

### Диагностика проблем

```bash
# Логи kubelet (на любой ноде):
sudo journalctl -u kubelet -f

# События в кластере (на master-ноде):
kubectl get events --sort-by=.metadata.creationTimestamp

# Подробная информация о ноде (на master-ноде):
kubectl describe node <NODE_NAME>
```