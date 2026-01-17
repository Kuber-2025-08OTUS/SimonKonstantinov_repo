# Сохранение результатов для сдачи задания

## Кластер успешно развернут! ✅

Все 5 нод в статусе Ready:
- 3 master-ноды (control-plane): node1, node2, node3
- 2 worker-ноды: node4, node5

## Сохранение файлов для сдачи

### Шаг 1: Сохранение inventory файла

```bash
# На ВМ k8s-learning-vm
cd /tmp/kubespray

# Копирование hosts.yaml в проект как inventory.ini
cp inventory/ha-cluster/hosts.yaml \
   /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/kubespray/inventory.ini

# Проверка сохраненного файла
cat /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/kubespray/inventory.ini
```

### Шаг 2: Сохранение вывода kubectl get nodes

```bash
# Создание директории outputs (если не существует)
mkdir -p /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs

# Сохранение вывода kubectl get nodes -o wide
kubectl get nodes -o wide > /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs/kubespray-nodes.txt

# Проверка сохраненного файла
cat /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs/kubespray-nodes.txt
```

## Ожидаемое содержимое файлов

### inventory.ini должен содержать:

```yaml
all:
  hosts:
    node1:
      ansible_host: 10.129.0.11
      ip: 10.129.0.11
      ...
  children:
    kube_control_plane:
      hosts:
        node1:
        node2:
        node3:
    kube_node:
      hosts:
        node4:
        node5:
```

### kubespray-nodes.txt должен содержать:

```
NAME    STATUS   ROLES           AGE   VERSION   INTERNAL-IP   ...
node1   Ready    control-plane   Xm    v1.34.3   10.129.0.11   ...
node2   Ready    control-plane   Xm    v1.34.3   10.129.0.30   ...
node3   Ready    control-plane   Xm    v1.34.3   10.129.0.31   ...
node4   Ready    <none>          Xm    v1.34.3   10.129.0.21   ...
node5   Ready    <none>          Xm    v1.34.3   10.129.0.5    ...
```

## Проверка файлов для сдачи

После сохранения проверьте:

```bash
cd /home/konstsima/SimonKonstantinov_repo/kubernetes-prod

# Проверка inventory файла
echo "=== Inventory файл ==="
cat kubespray/inventory.ini | head -30

# Проверка вывода kubectl get nodes
echo ""
echo "=== Вывод kubectl get nodes -o wide ==="
cat outputs/kubespray-nodes.txt
```

## Файлы для сдачи задания ✅

После выполнения вы должны иметь:

1. ✅ `kubespray/inventory.ini` - inventory файл с реальными IP-адресами
2. ✅ `outputs/kubespray-nodes.txt` - вывод `kubectl get nodes -o wide` с 5 нодами в статусе Ready

---

**Поздравляю! Задание со звездочкой выполнено! 🎉**
