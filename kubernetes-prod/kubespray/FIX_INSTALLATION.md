# Исправление установки kubespray

## Проблема

Команды выполнялись до завершения клонирования, или venv не создался правильно.

## Решение: Выполняйте команды последовательно

### Шаг 1: Дождаться завершения клонирования

```bash
cd /tmp
rm -rf kubespray  # Если нужно начать заново

# Клонирование (дождитесь завершения!)
git clone https://github.com/kubernetes-sigs/kubespray.git

# Проверка, что клонирование завершено
cd kubespray
ls -la
# Должны быть файлы: README.md, requirements.txt, и т.д.
```

### Шаг 2: Создание venv (после завершения клонирования)

```bash
# Убедитесь, что вы в директории kubespray
cd /tmp/kubespray
pwd
# Должно быть: /tmp/kubespray

# Создать venv
python3 -m venv venv

# Проверка, что venv создан
ls -la venv/
# Должна быть директория venv с поддиректориями bin/, lib/, и т.д.
```

### Шаг 3: Активация venv

```bash
# Активировать venv
source venv/bin/activate

# Проверка активации
which python3
# Должно быть: /tmp/kubespray/venv/bin/python3

# Проверка, что в начале строки есть (venv)
# В начале строки должно быть: (venv) root@k8s-learning-vm:/tmp/kubespray#
```

### Шаг 4: Установка зависимостей

```bash
# Обновить pip
pip install --upgrade pip

# Установить зависимости
pip install -r requirements.txt

# Это займет несколько минут...
```

### Шаг 5: Проверка установки

```bash
# Проверка Ansible
ansible --version

# Проверка Python
python3 --version
```

## Если venv не создается

1. **Проверьте Python:**
   ```bash
   python3 --version
   python3 -m venv --help
   ```

2. **Попробуйте создать venv с явным указанием Python:**
   ```bash
   python3 -m venv venv --python=python3
   ```

3. **Проверьте права доступа:**
   ```bash
   ls -la /tmp/kubespray
   # Убедитесь, что у вас есть права на запись
   ```

## Правильная последовательность (одна команда за раз)

```bash
# 1. Перейти в /tmp
cd /tmp

# 2. Удалить старую установку (если нужно)
rm -rf kubespray

# 3. Клонировать (ДОЖДИТЕСЬ ЗАВЕРШЕНИЯ!)
git clone https://github.com/kubernetes-sigs/kubespray.git

# 4. Перейти в директорию
cd kubespray

# 5. Проверить, что файлы есть
ls -la | head -10

# 6. Создать venv
python3 -m venv venv

# 7. Проверить, что venv создан
ls -la venv/

# 8. Активировать venv
source venv/bin/activate

# 9. Проверить активацию
which python3

# 10. Обновить pip
pip install --upgrade pip

# 11. Установить зависимости
pip install -r requirements.txt

# 12. Проверить установку
ansible --version
python3 --version
```
