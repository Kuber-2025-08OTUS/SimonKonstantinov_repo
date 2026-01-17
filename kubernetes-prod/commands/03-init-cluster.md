# Команды для инициализации кластера

## Текущее состояние кластера

- **Master нода:** k8s-master (10.129.0.3) - ✅ Инициализирована и готова
- **Worker ноды:** требуют присоединения к кластеру

## На master-ноде (уже выполнено)

### 1. Инициализация кластера ✅

```bash
# Выполнено:
kubeadm init --pod-network-cidr=10.244.0.0/16
```

**Результат:** Кластер инициализирован на master-ноде k8s-master (10.129.0.3)

### 2. Настройка kubectl ✅

```bash
# Выполнено:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 3. Установка Flannel (CNI плагин) ✅

```bash
# Выполнено:
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### 4. Текущий статус кластера

```bash
kubectl get nodes -o wide
```

**Текущий вывод (после инициализации):**
```
NAME         STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-master   Ready    control-plane   Xm      v1.34.x   10.129.0.3    <none>        Ubuntu 22.04 LTS     ...                   containerd://...
```

Master-нода в статусе `Ready` и готова к работе.

### 5. Сохранение статуса кластера до обновления ✅

```bash
# Выполнено:
kubectl get nodes -o wide > /tmp/nodes-before-upgrade.txt
# Сохранено в outputs/nodes-before-upgrade.txt
```

## На worker-нодах (требуется выполнить)

### Присоединение к кластеру

На каждой worker-ноде выполните команду `kubeadm join`:

**Команда для присоединения worker-нод:**

```bash
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
# На master-ноде выполните:
kubeadm token create --print-join-command
```

Используйте новый вывод команды для присоединения worker-нод.

## Проверка кластера

После присоединения всех worker-нод, проверьте на master-ноде:

```bash
# Проверка всех нод (должны быть все 4 ноды: 1 master + 3 worker)
kubectl get nodes -o wide

# Ожидаемый вывод после присоединения всех worker-нод:
# NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
# k8s-master     Ready    control-plane   Xm    v1.34.x   10.129.0.3    <none>        Ubuntu 22.04 LTS     ...                   containerd://...
# k8s-worker-1   Ready    <none>          Xm    v1.34.x   10.129.0.18   <none>        Ubuntu 22.04 LTS     ...                   containerd://...
# k8s-worker-2   Ready    <none>          Xm    v1.34.x   10.129.0.13   <none>        Ubuntu 22.04 LTS     ...                   containerd://...
# k8s-worker-3   Ready    <none>          Xm    v1.34.x   10.129.0.36   <none>        Ubuntu 22.04 LTS     ...                   containerd://...

# Проверка подов во всех namespace
kubectl get pods --all-namespaces

# Проверка системных подов
kubectl get pods -n kube-system

# Проверка подов Flannel
kubectl get pods -n kube-flannel
```

**Все ноды должны быть в статусе `Ready`.**

После присоединения всех worker-нод, обновите файл `outputs/nodes-before-upgrade.txt`:
```bash
kubectl get nodes -o wide > outputs/nodes-before-upgrade.txt
```
