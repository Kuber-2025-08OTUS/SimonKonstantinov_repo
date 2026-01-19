# Исправление проблемы с hosts.yaml

## Проблема

Ошибка при выполнении `ansible all -i inventory/ha-cluster/hosts.yaml -m ping`:
```
[WARNING]: Unable to parse /tmp/kubespray/inventory/ha-cluster/hosts.yaml as an inventory source
[WARNING]: No inventory was parsed, only implicit localhost is available
```

## Причины

1. Файл `hosts.yaml` не существует в `/tmp/kubespray/inventory/ha-cluster/`
2. Файл имеет неправильный формат YAML
3. Файл не был скопирован из проекта

## Решение

### Шаг 1: Проверка существования файла

```bash
# На ВМ k8s-learning-vm
cd /tmp/kubespray

# Проверка существования директории inventory/ha-cluster
ls -la inventory/ha-cluster/

# Проверка существования файла hosts.yaml
test -f inventory/ha-cluster/hosts.yaml && echo "✅ Файл существует" || echo "❌ Файл не найден"
```

### Шаг 2: Создание/копирование hosts.yaml

Если файл не существует, скопируйте его из проекта:

```bash
cd /tmp/kubespray
source venv/bin/activate

# Убедитесь, что директория существует
mkdir -p inventory/ha-cluster

# Копирование готового hosts.yaml из проекта
cp /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/kubespray/hosts.yaml \
   inventory/ha-cluster/hosts.yaml

# Проверка скопированного файла
cat inventory/ha-cluster/hosts.yaml
```

### Шаг 3: Проверка формата YAML

```bash
# Проверка синтаксиса YAML (если установлен yamllint)
yamllint inventory/ha-cluster/hosts.yaml

# Или проверка через Python
python3 -c "import yaml; yaml.safe_load(open('inventory/ha-cluster/hosts.yaml'))" && echo "✅ YAML валиден" || echo "❌ Ошибка YAML"

# Проверка через ansible-inventory
ansible-inventory -i inventory/ha-cluster/hosts.yaml --list
```

### Шаг 4: Проверка подключения

```bash
cd /tmp/kubespray
source venv/bin/activate

# Проверка подключения ко всем нодам
ansible all -i inventory/ha-cluster/hosts.yaml -m ping
```

## Если файл все еще не работает

### Создать файл вручную на ВМ:

```bash
cd /tmp/kubespray/inventory/ha-cluster

cat > hosts.yaml <<'EOF'
all:
  hosts:
    node1:
      ansible_host: 10.129.0.11
      ip: 10.129.0.11
      access_ip: 10.129.0.11
    node2:
      ansible_host: 10.129.0.30
      ip: 10.129.0.30
      access_ip: 10.129.0.30
    node3:
      ansible_host: 10.129.0.31
      ip: 10.129.0.31
      access_ip: 10.129.0.31
    node4:
      ansible_host: 10.129.0.21
      ip: 10.129.0.21
      access_ip: 10.129.0.21
    node5:
      ansible_host: 10.129.0.5
      ip: 10.129.0.5
      access_ip: 10.129.0.5
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

# Проверка файла
cat hosts.yaml
```

## Ожидаемый результат

После исправления команда `ansible all -i inventory/ha-cluster/hosts.yaml -m ping` должна показать:

```
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
node2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
...
```

Все 5 нод должны ответить `pong`.
