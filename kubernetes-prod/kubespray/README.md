# Задание со * - HA-кластер Kubernetes с kubespray

## Требования задания

Создать минимум 5 нод следующей конфигурации:
- **Master ноды**: 3 узла, 2vCPU, 8GB RAM каждая
- **Worker ноды**: минимум 2 узла, 2vCPU, 8GB RAM каждая

Развернуть отказоустойчивый кластер K8s с помощью kubespray (3 master ноды, минимум 2 worker).

## Что нужно для сдачи

К результатам ДЗ необходимо приложить:

1. **Inventory файл** - который использовался для создания кластера (`inventory.ini` или `hosts.yaml`)
2. **Вывод команды** `kubectl get nodes -o wide` (сохранить в `../outputs/kubespray-nodes.txt`)

## Пошаговый план

### Шаг 1: Создание ВМ

Создайте 5 ВМ в Yandex Cloud:
- 3 master-ноды: k8s-ha-master-1, k8s-ha-master-2, k8s-ha-master-3 (2vCPU, 8GB RAM)
- 2 worker-ноды: k8s-ha-worker-1, k8s-ha-worker-2 (2vCPU, 8GB RAM)

**Используйте скрипт:**
```bash
cd /home/konstsima/SimonKonstantinov_repo/kubernetes-prod
./scripts/create-vms-ha.sh
```

**Важно:** Информация о созданных ВМ сохранится в `kubespray/vms-ha-info.txt` в проекте.

После выполнения скрипта проверьте файл:
```bash
cat kubespray/vms-ha-info.txt
```

Вы увидите список ВМ с IP-адресами:
```
VM_NAME,EXTERNAL_IP,INTERNAL_IP,USERNAME,PASSWORD
k8s-ha-master-1,<EXTERNAL_IP>,<INTERNAL_IP>,master1,master1
...
```

### Шаг 2: Развертывание кластера с kubespray

**ВАЖНО:** Развертывание должно выполняться из ВМ в облаке (например, k8s-learning-vm), так как worker-ноды доступны только через Internal IP.

#### 2.1. Установка kubespray на ВМ в облаке

**ВАЖНО:** Если kubespray уже установлен в `/tmp/kubespray`, используйте существующую установку (см. ниже).

```bash
# На ВМ k8s-learning-vm:

# Вариант 1: Если kubespray уже установлен (РЕКОМЕНДУЕТСЯ)
cd /tmp/kubespray
if [ -d "venv" ]; then
    source venv/bin/activate
else
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# Вариант 2: Если нужно установить с нуля
# cd /tmp
# rm -rf kubespray  # Удалить существующую установку, если нужно
# git clone https://github.com/kubernetes-sigs/kubespray.git
# cd kubespray
# python3 -m venv venv
# source venv/bin/activate
# pip install --upgrade pip
# pip install -r requirements.txt

# Проверка установки
echo "Проверка Ansible:"
ansible --version

echo "Проверка Python:"
python3 --version

# Если команды не дают вывода или выдают ошибки, выполните:
# source venv/bin/activate  # Активировать venv
# pip install --upgrade pip
# pip install -r requirements.txt
```

#### 2.2. Создание inventory

```bash
cd /tmp/kubespray
source venv/bin/activate

# Копирование структуры inventory
cp -rfp inventory/sample inventory/ha-cluster

# Создание hosts.yaml с реальными IP из kubespray/vms-ha-info.txt
cd inventory/ha-cluster
cat > hosts.yaml <<'EOF'
all:
  hosts:
    node1:
      ansible_host: <MASTER1_INTERNAL_IP>
      ip: <MASTER1_INTERNAL_IP>
      access_ip: <MASTER1_INTERNAL_IP>
    node2:
      ansible_host: <MASTER2_INTERNAL_IP>
      ip: <MASTER2_INTERNAL_IP>
      access_ip: <MASTER2_INTERNAL_IP>
    node3:
      ansible_host: <MASTER3_INTERNAL_IP>
      ip: <MASTER3_INTERNAL_IP>
      access_ip: <MASTER3_INTERNAL_IP>
    node4:
      ansible_host: <WORKER1_INTERNAL_IP>
      ip: <WORKER1_INTERNAL_IP>
      access_ip: <WORKER1_INTERNAL_IP>
    node5:
      ansible_host: <WORKER2_INTERNAL_IP>
      ip: <WORKER2_INTERNAL_IP>
      access_ip: <WORKER2_INTERNAL_IP>
  children:
    kube_control_plane:
      hosts:
        node1:
        node2:
        node3:
    etcd:
      hosts:
        node1:
        node2:
        node3:
    kube_node:
      hosts:
        node4:
        node5:
    calico_rr:
      hosts: {}
EOF

# ЗАМЕНИТЕ IP-АДРЕСА НА РЕАЛЬНЫЕ ИЗ kubespray/vms-ha-info.txt!
```

#### 2.3. Настройка Ansible

```bash
cd /tmp/kubespray

cat > ansible.cfg <<EOF
[defaults]
inventory = inventory/ha-cluster/hosts.yaml
remote_user = root
private_key_file = /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key
host_key_checking = False
interpreter_python = auto_silent
roles_path = /tmp/kubespray/roles
EOF

# Проверка подключения
source venv/bin/activate
ansible all -i inventory/ha-cluster/hosts.yaml -m ping
```

#### 2.4. Развертывание кластера

```bash
cd /tmp/kubespray
source venv/bin/activate

# Развертывание HA-кластера (займет 15-30 минут)
ansible-playbook -i inventory/ha-cluster/hosts.yaml \
  --become --become-user=root \
  cluster.yml -v
```

### Шаг 3: Настройка kubectl

```bash
# Создание директории для kubeconfig
mkdir -p ~/.kube

# Копирование kubeconfig с первой master-ноды
# IP-адрес: 10.129.0.11 (k8s-ha-master-1 из kubespray/vms-ha-info.txt)
scp -i /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key \
    root@10.129.0.11:/etc/kubernetes/admin.conf \
    ~/.kube/config

# Установка правильных прав доступа
chmod 600 ~/.kube/config

# Проверка подключения
kubectl cluster-info
kubectl get nodes -o wide
```

### Шаг 4: Сохранение результатов для сдачи

```bash
# Сохранение inventory файла
cp /tmp/kubespray/inventory/ha-cluster/hosts.yaml \
   /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/kubespray/inventory.ini

# Сохранение вывода kubectl get nodes
mkdir -p /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs
kubectl get nodes -o wide > /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs/kubespray-nodes.txt

# Проверка сохраненных файлов
cat /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs/kubespray-nodes.txt
```

## Файлы для сдачи

После выполнения у вас должны быть:

1. ✅ `kubespray/inventory.ini` - inventory файл с реальными IP-адресами
2. ✅ `outputs/kubespray-nodes.txt` - вывод `kubectl get nodes -o wide`

## Полезные ссылки

- [Официальная документация Kubespray](https://kubespray.io/)
- [Репозиторий Kubespray на GitHub](https://github.com/kubernetes-sigs/kubespray)
- [Документация по HA кластеру](https://kubespray.io/#/docs/ha-mode)
