#!/bin/bash
# Скрипт для установки Yandex Cloud CLI на Ubuntu/Debian

set -e

echo "=== Установка Yandex Cloud CLI ==="

# Проверка, что скрипт запущен от root или с sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Запустите скрипт с sudo: sudo bash install-yc-cli.sh"
    exit 1
fi

# Определение архитектуры
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH_TYPE="amd64"
        ;;
    aarch64|arm64)
        ARCH_TYPE="arm64"
        ;;
    *)
        echo "Неподдерживаемая архитектура: $ARCH"
        exit 1
        ;;
esac

echo "Архитектура: $ARCH_TYPE"

# Создание временной директории
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Скачивание YC CLI
echo "Скачивание YC CLI..."
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash

# Добавление в PATH (если еще не добавлен)
if ! echo "$PATH" | grep -q "$HOME/.yandex-cloud/bin"; then
    echo 'export PATH=$PATH:$HOME/.yandex-cloud/bin' >> ~/.bashrc
    export PATH=$PATH:$HOME/.yandex-cloud/bin
fi

# Проверка установки
if command -v yc &> /dev/null; then
    echo "✓ YC CLI успешно установлен"
    yc version
    echo ""
    echo "Для инициализации выполните:"
    echo "  yc init"
else
    # Попытка найти yc в стандартных местах
    if [ -f "$HOME/.yandex-cloud/bin/yc" ]; then
        echo "✓ YC CLI установлен в $HOME/.yandex-cloud/bin/yc"
        echo "Добавьте в PATH: export PATH=\$PATH:\$HOME/.yandex-cloud/bin"
        echo "Или используйте полный путь: $HOME/.yandex-cloud/bin/yc"
    else
        echo "✗ Ошибка установки YC CLI"
        exit 1
    fi
fi

# Очистка
cd /
rm -rf "$TMP_DIR"

echo ""
echo "=== Установка завершена ==="
