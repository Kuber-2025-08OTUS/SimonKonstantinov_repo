# Быстрое присоединение worker-нод к кластеру

## Актуальная команда join

```bash
sudo kubeadm join 10.129.0.3:6443 --token i8yglu.rmfyl2eii4hg9qp1 --discovery-token-ca-cert-hash sha256:584cb2940ffb2d8be6b6712c9bac205d3d3d2a85b7eb164b3dc8483df658d81b
```

## Пошаговая инструкция

### 1. Присоединение k8s-worker-1

```bash
# Подключение к worker-1
ssh -i k8s-key node1@158.160.90.73

# Выполнение команды join
sudo kubeadm join 10.129.0.3:6443 --token i8yglu.rmfyl2eii4hg9qp1 --discovery-token-ca-cert-hash sha256:584cb2940ffb2d8be6b6712c9bac205d3d3d2a85b7eb164b3dc8483df658d81b
```

### 2. Присоединение k8s-worker-2

```bash
# Подключение к worker-2
ssh -i k8s-key node2@158.160.77.22

# Выполнение команды join
sudo kubeadm join 10.129.0.3:6443 --token i8yglu.rmfyl2eii4hg9qp1 --discovery-token-ca-cert-hash sha256:584cb2940ffb2d8be6b6712c9bac205d3d3d2a85b7eb164b3dc8483df658d81b
```

### 3. Присоединение k8s-worker-3

```bash
# Подключение к worker-3
ssh -i k8s-key node3@158.160.73.156

# Выполнение команды join
sudo kubeadm join 10.129.0.3:6443 --token i8yglu.rmfyl2eii4hg9qp1 --discovery-token-ca-cert-hash sha256:584cb2940ffb2d8be6b6712c9bac205d3d3d2a85b7eb164b3dc8483df658d81b
```

## Проверка после присоединения

После присоединения всех worker-нод, проверьте на master-ноде:

```bash
# Подключение к master-ноде
ssh -i k8s-key master@158.160.69.114

# Проверка статуса всех нод
kubectl get nodes -o wide
```

**Ожидаемый результат:** Все 4 ноды должны быть в статусе `Ready`.

## Если токен истек

Если при выполнении команды join вы получили ошибку о том, что токен истек, создайте новый токен на master-ноде:

```bash
# На master-ноде:
kubeadm token create --print-join-command
```

Используйте новый вывод команды для присоединения worker-нод.