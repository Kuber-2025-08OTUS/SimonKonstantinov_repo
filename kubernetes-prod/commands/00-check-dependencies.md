# Проверка зависимостей и текущего состояния

Выполните эти команды для проверки готовности системы к развертыванию кластера.

## Проверка ВМ в Yandex Cloud

```bash
# Список всех ВМ
yc compute instance list

# Детальная информация о конкретной ВМ
yc compute instance get <VM_NAME>

# Проверка статуса ВМ
yc compute instance list --format table
```

## Проверка подключения к ВМ

```bash
# Проверка доступности ВМ по SSH
ssh <USER>@<VM_IP> "echo 'Connection OK'"

# Или через yc
yc compute instance list --format json | jq '.[] | {name: .name, external_ip: .network_interfaces[0].primary_v4_address.one_to_one_nat.address}'
```

## Проверка текущего состояния Kubernetes (если уже установлен)

На каждой ВМ выполните:

```bash
# Проверка версии Kubernetes компонентов
kubeadm version 2>/dev/null || echo "kubeadm не установлен"
kubectl version --client 2>/dev/null || echo "kubectl не установлен"
kubelet --version 2>/dev/null || echo "kubelet не установлен"

# Проверка containerd
containerd --version 2>/dev/null || echo "containerd не установлен"

# Проверка статуса сервисов
systemctl status containerd 2>/dev/null || echo "containerd не установлен"
systemctl status kubelet 2>/dev/null || echo "kubelet не установлен"

# Проверка swap
swapon --show || echo "Swap отключен (OK)"

# Проверка параметров ядра
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward

# Проверка модулей ядра
lsmod | grep -E "overlay|br_netfilter"
```

## Проверка кластера (если уже развернут)

На master-ноде:

```bash
# Проверка нод кластера
kubectl get nodes -o wide 2>/dev/null || echo "Кластер не инициализирован"

# Проверка версии кластера
kubectl version --short 2>/dev/null || echo "Кластер не доступен"

# Проверка системных подов
kubectl get pods --all-namespaces 2>/dev/null || echo "Кластер не доступен"

# Проверка CNI плагина
kubectl get pods -n kube-flannel 2>/dev/null || echo "Flannel не установлен"
```

## Проверка требований к ВМ

Для выполнения задания требуется:
- **Master-нода**: 1 узел, 2vCPU, 8GB RAM
- **Worker-ноды**: 3 узла, 2vCPU, 8GB RAM

Проверка ресурсов ВМ:

```bash
# На ВМ выполните:
free -h  # Проверка RAM
nproc    # Проверка CPU
df -h    # Проверка дискового пространства
```

## Определение версии Kubernetes

```bash
# Узнайте актуальную версию Kubernetes
curl -L https://dl.k8s.io/release/stable.txt

# Список всех доступных версий
curl -L https://dl.k8s.io/release/stable.txt

# Для установки используйте версию на одну ниже актуальной
# Например, если актуальная 1.30.x, то используйте 1.29.x
```

## Чеклист перед началом работы

- [ ] Созданы 4 ВМ в Yandex Cloud (1 master + 3 worker)
- [ ] ВМ имеют достаточные ресурсы (2vCPU, 8GB RAM каждая)
- [ ] Определена версия Kubernetes для установки
- [ ] Есть доступ по SSH ко всем ВМ
- [ ] На всех ВМ отключен swap
- [ ] На всех ВМ настроена маршрутизация
- [ ] На всех ВМ установлен containerd
- [ ] На всех ВМ установлены kubeadm, kubelet, kubectl
