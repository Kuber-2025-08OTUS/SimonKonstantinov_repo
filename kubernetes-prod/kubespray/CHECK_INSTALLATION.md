# Проверка установки kubespray

## Команды для проверки

После активации venv выполните следующие команды для проверки установки:

```bash
cd /tmp/kubespray
source venv/bin/activate

# Проверка Ansible
echo "=== Ansible ==="
ansible --version

# Проверка Python
echo "=== Python ==="
python3 --version

# Проверка установленных пакетов
echo "=== Установленные пакеты ==="
pip list | grep -E "ansible|jinja2|netaddr"
```

## Ожидаемый результат

### Ansible версия:
```
ansible [core 2.x.x]
  python version = 3.x.x
  ...
```

### Python версия:
```
Python 3.x.x
```

## Если команды не дают вывода

1. **Проверьте, что venv активирован:**
   ```bash
   which python3
   # Должно быть: /tmp/kubespray/venv/bin/python3
   
   which ansible
   # Должно быть: /tmp/kubespray/venv/bin/ansible
   ```

2. **Если venv не активирован, активируйте:**
   ```bash
   cd /tmp/kubespray
   source venv/bin/activate
   ```

3. **Если пакеты не установлены, установите:**
   ```bash
   cd /tmp/kubespray
   source venv/bin/activate
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

## Продолжение работы

После успешной проверки продолжайте с созданием inventory (Шаг 2.2 в README.md).
