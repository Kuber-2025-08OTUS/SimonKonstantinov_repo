# Настройка Ansible на ВМ k8s-learning-vm

## Готовые файлы для использования

В проекте созданы готовые файлы:
- `kubespray/ansible.cfg` - конфигурация Ansible
- `kubespray/hosts.yaml` - inventory файл с реальными IP

## Инструкция для выполнения на ВМ k8s-learning-vm

### Шаг 1: Копирование готовых файлов

```bash
# На ВМ k8s-learning-vm

cd /tmp/kubespray
source venv/bin/activate

# Копирование структуры inventory (если еще не создана)
cp -rfp inventory/sample inventory/ha-cluster

# Копирование готового hosts.yaml из проекта
cp /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/kubespray/hosts.yaml \
   inventory/ha-cluster/hosts.yaml

# Копирование готового ansible.cfg из проекта
cp /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/kubespray/ansible.cfg \
   /tmp/kubespray/ansible.cfg

# Проверка файлов
cat inventory/ha-cluster/hosts.yaml
cat ansible.cfg
```

### Шаг 2: Проверка SSH ключа

```bash
# Проверка наличия SSH ключа
test -f /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key && \
    echo "✅ SSH ключ найден" || \
    echo "❌ SSH ключ не найден"

# Проверка прав на ключ (должен быть 600)
ls -la /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key

# Если права неправильные, установите:
chmod 600 /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key
```

### Шаг 3: Проверка подключения через Ansible

```bash
cd /tmp/kubespray
source venv/bin/activate

# Проверка подключения ко всем нодам
ansible all -i inventory/ha-cluster/hosts.yaml -m ping
```

## Ожидаемый результат

После выполнения `ansible all -i inventory/ha-cluster/hosts.yaml -m ping` вы должны увидеть:

```
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
node2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
node3 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
node4 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
node5 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Все 5 нод должны ответить `pong`.

## Если есть ошибки

1. **Проверьте SSH ключ:**
   ```bash
   # Попробуйте подключиться вручную
   ssh -i /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/k8s-key root@10.129.0.11
   ```

2. **Проверьте IP-адреса в hosts.yaml:**
   ```bash
   cat inventory/ha-cluster/hosts.yaml
   # Сравните с kubespray/vms-ha-info.txt
   ```

3. **Проверьте, что вы на ВМ в облаке:**
   - Worker-ноды доступны только через Internal IP
   - Развертывание должно выполняться из ВМ в облаке

## Следующие шаги

После успешной проверки подключения продолжайте с шага 2.4 (развертывание кластера) в README.md.
