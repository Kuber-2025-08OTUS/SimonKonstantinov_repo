# Kubespray уже установлен на ВМ

## Проблема

При попытке клонировать kubespray получаем ошибку:
```
fatal: destination path 'kubespray' already exists and is not an empty directory.
```

Это означает, что kubespray уже установлен в `/tmp/kubespray` на ВМ k8s-learning-vm.

## Решение

### Вариант 1: Использовать существующую установку (РЕКОМЕНДУЕТСЯ)

```bash
# Перейти в существующую директорию
cd /tmp/kubespray

# Активировать виртуальное окружение (если уже создано)
source venv/bin/activate

# Если venv не существует, создать его
if [ ! -d "venv" ]; then
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# Проверка установки
ansible --version
python3 --version
```

### Вариант 2: Обновить существующую установку

```bash
cd /tmp/kubespray

# Обновить kubespray
git pull

# Обновить зависимости
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Вариант 3: Переустановить с нуля (если нужна чистая установка)

```bash
# Удалить существующую директорию
rm -rf /tmp/kubespray

# Клонировать заново
cd /tmp
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## Рекомендация

**Используйте Вариант 1** - проверьте, что установка работает, и продолжайте с существующей установкой.
