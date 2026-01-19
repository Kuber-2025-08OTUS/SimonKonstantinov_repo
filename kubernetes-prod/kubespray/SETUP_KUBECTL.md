# Настройка kubectl после развертывания кластера

## Инструкция для выполнения на ВМ k8s-learning-vm

### Шаг 1: Создание директории для kubeconfig

```bash
mkdir -p ~/.kube
```

### Шаг 2: Копирование kubeconfig с первой master-ноды

```bash
# IP-адрес: 10.129.0.11 (k8s-ha-master-1)
scp -i /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key \
    root@10.129.0.11:/etc/kubernetes/admin.conf \
    ~/.kube/config
```

### Шаг 3: Установка правильных прав доступа

```bash
chmod 600 ~/.kube/config
```

### Шаг 4: Проверка подключения к кластеру

```bash
# Проверка информации о кластере
kubectl cluster-info

# Проверка статуса нод
kubectl get nodes -o wide
```

## Ожидаемый результат

После выполнения `kubectl get nodes -o wide` вы должны увидеть все 5 нод:

```
NAME    STATUS   ROLES           AGE   VERSION   INTERNAL-IP   ...
node1   Ready    control-plane   Xm    v1.x.x    10.129.0.11   ...
node2   Ready    control-plane   Xm    v1.x.x    10.129.0.30   ...
node3   Ready    control-plane   Xm    v1.x.x    10.129.0.31   ...
node4   Ready    <none>          Xm    v1.x.x    10.129.0.21   ...
node5   Ready    <none>          Xm    v1.x.x    10.129.0.5    ...
```

Все ноды должны быть в статусе `Ready`.

## Если файл admin.conf не найден

Ошибка: `scp: /etc/kubernetes/admin.conf: No such file or directory`

**Причина:** Кластер еще не развернут или развертывание не завершено.

**Решение:** 
1. Дождитесь завершения развертывания кластера (команда `ansible-playbook cluster.yml` должна завершиться успешно)
2. Проверьте, что развертывание завершилось без ошибок
3. Попробуйте скопировать kubeconfig снова

## Следующие шаги

После успешной настройки kubectl:

1. Сохранить inventory файл для сдачи:
   ```bash
   cp /tmp/kubespray/inventory/ha-cluster/hosts.yaml \
      /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/kubespray/inventory.ini
   ```

2. Сохранить вывод kubectl get nodes:
   ```bash
   mkdir -p /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs
   kubectl get nodes -o wide > /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs/kubespray-nodes.txt
   ```
