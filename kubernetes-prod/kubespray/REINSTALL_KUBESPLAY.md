# Переустановка kubespray с нуля

## Инструкция для выполнения на ВМ k8s-learning-vm

### Шаг 1: Удаление существующей установки

```bash
# Перейти в /tmp
cd /tmp

# Удалить существующую директорию kubespray
rm -rf kubespray

# Проверка, что директория удалена
ls -la | grep kubespray
# (не должно быть вывода)
```

### Шаг 2: Клонирование kubespray

```bash
# Клонировать kubespray заново
git clone https://github.com/kubernetes-sigs/kubespray.git

# Перейти в директорию
cd kubespray

# Проверка, что клонирование прошло успешно
ls -la
```

### Шаг 3: Создание виртуального окружения

```bash
# Создать виртуальное окружение Python
python3 -m venv venv

# Активировать виртуальное окружение
source venv/bin/activate

# Проверка активации (в начале строки должно быть (venv))
echo "Venv activated: $VIRTUAL_ENV"
```

### Шаг 4: Установка зависимостей

```bash
# Обновить pip
pip install --upgrade pip

# Установить зависимости из requirements.txt
pip install -r requirements.txt

# Это займет несколько минут...
```

### Шаг 5: Проверка установки

```bash
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

После выполнения вы должны увидеть:

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

### Установленные пакеты:
```
ansible             x.x.x
jinja2              x.x.x
netaddr             x.x.x
...
```

## Если что-то пошло не так

1. **Проверьте, что вы в правильной директории:**
   ```bash
   pwd
   # Должно быть: /tmp/kubespray
   ```

2. **Проверьте, что venv активирован:**
   ```bash
   which python3
   # Должно быть: /tmp/kubespray/venv/bin/python3
   ```

3. **Если есть ошибки при установке зависимостей:**
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt --verbose
   ```

## Следующие шаги

После успешной переустановки продолжайте с шага 2.2 (создание inventory) в README.md.
