#!/bin/bash
# Скрипт для создания 4 ВМ в Yandex Cloud для Kubernetes кластера
# Требования: 1 master (2vCPU, 8GB RAM) + 3 worker (2vCPU, 8GB RAM)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Создание ВМ для Kubernetes кластера ===${NC}"
echo ""

# Проверка наличия yc CLI
if ! command -v yc &> /dev/null; then
    echo -e "${RED}Ошибка: yc CLI не установлен${NC}"
    echo "Установите Yandex Cloud CLI: https://cloud.yandex.ru/docs/cli/quickstart"
    exit 1
fi

# Проверка авторизации
if ! yc config list &> /dev/null; then
    echo -e "${RED}Ошибка: YC CLI не настроен${NC}"
    echo "Выполните: yc init"
    exit 1
fi

# Получение параметров
echo "Введите параметры для создания ВМ:"
echo ""

read -p "Folder ID (нажмите Enter для использования текущего): " FOLDER_ID
if [ -z "$FOLDER_ID" ]; then
    FOLDER_ID=$(yc config get folder-id 2>/dev/null || echo "")
    if [ -z "$FOLDER_ID" ]; then
        echo -e "${RED}Ошибка: Folder ID не указан${NC}"
        exit 1
    fi
fi

read -p "Zone (по умолчанию: ru-central1-a): " ZONE
ZONE=${ZONE:-ru-central1-a}

read -p "Subnet ID (нажмите Enter для автоматического поиска): " SUBNET_ID
if [ -z "$SUBNET_ID" ]; then
    echo "Поиск подсети..."
    SUBNET_ID=$(yc vpc subnet list --format json 2>/dev/null | jq -r '.[0].id // empty')
    if [ -n "$SUBNET_ID" ]; then
        SUBNET_NAME=$(yc vpc subnet list --format json 2>/dev/null | jq -r ".[] | select(.id == \"$SUBNET_ID\") | .name")
        echo "Найдена подсеть: $SUBNET_NAME ($SUBNET_ID)"
    else
        echo -e "${YELLOW}Подсеть не найдена. Создайте подсеть вручную или укажите Subnet ID.${NC}"
        read -p "Введите Subnet ID: " SUBNET_ID
    fi
fi

read -p "Образ Ubuntu (нажмите Enter для поиска автоматически): " IMAGE_ID

# Поиск образа Ubuntu, если не указан
if [ -z "$IMAGE_ID" ]; then
    echo "Поиск образа Ubuntu..."
    # Сначала пробуем Ubuntu 22.04
    IMAGE_ID=$(yc compute image list --folder-id standard-images --format json 2>/dev/null | \
        jq -r '.[] | select(.family != null and (.family | contains("ubuntu-22") or contains("ubuntu-2204"))) | .id' | head -1)
    
    # Если не нашли, пробуем Ubuntu 20.04
    if [ -z "$IMAGE_ID" ]; then
        IMAGE_ID=$(yc compute image list --folder-id standard-images --format json 2>/dev/null | \
            jq -r '.[] | select(.family != null and (.family | contains("ubuntu-20") or contains("ubuntu-2004"))) | .id' | head -1)
    fi
    
    if [ -z "$IMAGE_ID" ]; then
        echo -e "${YELLOW}Не удалось найти образ автоматически.${NC}"
        echo "Доступные образы Ubuntu:"
        yc compute image list --folder-id standard-images --format json 2>/dev/null | \
            jq -r '.[] | select(.family != null and (.family | contains("ubuntu"))) | "\(.id) | \(.family) | \(.name)"' | head -5
        read -p "Введите Image ID: " IMAGE_ID
    else
        IMAGE_NAME=$(yc compute image list --folder-id standard-images --format json 2>/dev/null | \
            jq -r ".[] | select(.id == \"$IMAGE_ID\") | .family // .name")
        echo "Найден образ: $IMAGE_NAME ($IMAGE_ID)"
    fi
fi

read -p "SSH ключ (путь к файлу или содержимое, нажмите Enter для ~/.ssh/id_rsa.pub): " SSH_KEY_PATH
if [ -z "$SSH_KEY_PATH" ]; then
    SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
fi

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}Ошибка: SSH ключ не найден: $SSH_KEY_PATH${NC}"
    exit 1
fi

SSH_KEY=$(cat "$SSH_KEY_PATH")

echo ""
echo -e "${GREEN}Параметры создания:${NC}"
echo "  Folder ID: $FOLDER_ID"
echo "  Zone: $ZONE"
echo "  Image ID: $IMAGE_ID"
echo "  SSH Key: $SSH_KEY_PATH"
echo ""
read -p "Продолжить создание ВМ? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Отменено"
    exit 0
fi

# Функция создания ВМ
create_vm() {
    local VM_NAME=$1
    local VM_ROLE=$2
    local CPU=$3
    local MEMORY=$4
    
    echo ""
    echo -e "${GREEN}Создание ВМ: $VM_NAME ($VM_ROLE)${NC}"
    
    # Создание ВМ
    yc compute instance create \
        --name "$VM_NAME" \
        --folder-id "$FOLDER_ID" \
        --zone "$ZONE" \
        --network-interface subnet-id="$SUBNET_ID",nat-ip-version=ipv4 \
        --create-boot-disk image-id="$IMAGE_ID",size=20 \
        --cores "$CPU" \
        --memory "${MEMORY}GB" \
        --metadata-from-file ssh-keys=/dev/stdin <<< "$SSH_KEY" \
        --platform-id standard-v3 \
        --hostname "$VM_NAME" \
        --format json > /tmp/"$VM_NAME".json
    
    if [ $? -eq 0 ]; then
        VM_IP=$(jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address' /tmp/"$VM_NAME".json)
        VM_INT_IP=$(jq -r '.network_interfaces[0].primary_v4_address.address' /tmp/"$VM_NAME".json)
        echo -e "${GREEN}✓ ВМ $VM_NAME создана${NC}"
        echo "  External IP: $VM_IP"
        echo "  Internal IP: $VM_INT_IP"
        echo "$VM_NAME,$VM_IP,$VM_INT_IP" >> /tmp/k8s-vms.csv
    else
        echo -e "${RED}✗ Ошибка при создании ВМ $VM_NAME${NC}"
        return 1
    fi
}

# Создание файла для хранения информации о ВМ
echo "VM_NAME,EXTERNAL_IP,INTERNAL_IP" > /tmp/k8s-vms.csv

# Создание master-ноды
create_vm "k8s-master" "master" 2 8

# Создание worker-нод
for i in {1..3}; do
    create_vm "k8s-worker-$i" "worker" 2 8
done

echo ""
echo -e "${GREEN}=== Все ВМ созданы ===${NC}"
echo ""
echo "Список созданных ВМ:"
echo "===================="
cat /tmp/k8s-vms.csv | column -t -s','
echo ""
echo "Информация сохранена в: /tmp/k8s-vms.csv"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Подождите 1-2 минуты для полной инициализации ВМ"
echo "2. Проверьте доступность ВМ: ping <EXTERNAL_IP>"
echo "3. Подключитесь к ВМ: ssh <USER>@<EXTERNAL_IP>"
echo "4. Следуйте инструкциям в commands/01-prepare-master.md и commands/02-prepare-worker.md"
