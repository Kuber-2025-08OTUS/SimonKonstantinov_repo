# Исправление проблемы с kubectl подключением

## Проблема

Ошибка при выполнении `kubectl cluster-info`:
```
The connection to the server 127.0.0.1:6443 was refused
```

Kubectl пытается подключиться к `127.0.0.1:6443` вместо правильного адреса master-ноды.

## Возможные причины

1. **Кластер еще не развернут** - файл admin.conf скопирован, но кластер еще не развернут
2. **В admin.conf указан localhost** - вместо правильного IP-адреса
3. **API-сервер не запущен** - кластер развернут, но API-сервер не работает

## Решение

### Шаг 1: Проверка, развернут ли кластер

```bash
# На ВМ k8s-learning-vm

# Проверка, существует ли admin.conf на master-ноде
ssh -i /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key \
    root@10.129.0.11 "test -f /etc/kubernetes/admin.conf && echo 'Файл существует' || echo 'Файл не найден'"

# Проверка статуса kubelet на master-ноде
ssh -i /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key \
    root@10.129.0.11 "systemctl status kubelet | head -5"
```

Если файл не найден или kubelet не запущен - **кластер еще не развернут!**

### Шаг 2: Проверка содержимого admin.conf

```bash
# Проверка содержимого скопированного kubeconfig
cat ~/.kube/config | grep server

# Должен быть адрес типа: server: https://10.129.0.11:6443
# НЕ должно быть: server: https://127.0.0.1:6443
```

### Шаг 3: Исправление kubeconfig (если указан localhost)

Если в kubeconfig указан `127.0.0.1`, нужно заменить на правильный IP:

```bash
# Проверка текущего адреса
kubectl config view | grep server

# Если указан 127.0.0.1, замените на правильный IP
sed -i 's|server: https://127.0.0.1:6443|server: https://10.129.0.11:6443|' ~/.kube/config

# Или установите правильный адрес явно
kubectl config set-cluster kubernetes --server=https://10.129.0.11:6443

# Проверка после изменения
kubectl config view | grep server
```

### Шаг 4: Проверка подключения

```bash
# Проверка подключения к кластеру
kubectl cluster-info

# Проверка статуса нод
kubectl get nodes -o wide
```

## Если кластер еще не развернут

**ВАЖНО:** Настройка kubectl должна выполняться **ПОСЛЕ** успешного развертывания кластера!

Сначала разверните кластер:

```bash
cd /tmp/kubespray
source venv/bin/activate

# Развертывание HA-кластера (займет 15-30 минут)
ansible-playbook -i inventory/ha-cluster/hosts.yaml \
  --become --become-user=root \
  cluster.yml -v
```

Только после успешного завершения развертывания настраивайте kubectl!

## Ожидаемый результат

После исправления `kubectl cluster-info` должен показать:

```
Kubernetes control plane is running at https://10.129.0.11:6443
CoreDNS is running at https://10.129.0.11:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
...
```

А `kubectl get nodes -o wide` должен показать все 5 нод в статусе `Ready`.
