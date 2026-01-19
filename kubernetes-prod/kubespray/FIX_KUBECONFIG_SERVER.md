# Исправление адреса сервера в kubeconfig

## Проблема

В `~/.kube/config` указан неправильный адрес сервера:
```
server: https://127.0.0.1:6443
```

Должно быть:
```
server: https://10.129.0.11:6443
```

## Решение

### Вариант 1: Исправление через sed (быстро)

```bash
# Замена localhost на правильный IP
sed -i 's|server: https://127.0.0.1:6443|server: https://10.129.0.11:6443|' ~/.kube/config

# Проверка изменения
cat ~/.kube/config | grep server

# Должно быть: server: https://10.129.0.11:6443
```

### Вариант 2: Исправление через kubectl config

```bash
# Установка правильного адреса сервера
kubectl config set-cluster kubernetes --server=https://10.129.0.11:6443

# Проверка изменения
kubectl config view | grep server
```

### Вариант 3: Перекопировать admin.conf (если на master-ноде правильный адрес)

```bash
# Удалить старый kubeconfig
rm ~/.kube/config

# Перекопировать admin.conf с master-ноды
scp -i /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key \
    root@10.129.0.11:/etc/kubernetes/admin.conf \
    ~/.kube/config

chmod 600 ~/.kube/config

# Проверка адреса
cat ~/.kube/config | grep server
```

## После исправления

```bash
# Проверка подключения к кластеру
kubectl cluster-info

# Проверка статуса нод
kubectl get nodes -o wide
```

## Ожидаемый результат

После исправления `kubectl cluster-info` должен показать:

```
Kubernetes control plane is running at https://10.129.0.11:6443
CoreDNS is running at https://10.129.0.11:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
...
```

А `kubectl get nodes -o wide` должен показать все 5 нод в статусе `Ready`.
