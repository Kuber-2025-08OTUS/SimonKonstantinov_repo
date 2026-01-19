#!/bin/bash
# Автоматический скрипт для создания 5 ВМ в Yandex Cloud для HA-кластера Kubernetes с kubespray
# Требования: 3 master (2vCPU, 8GB RAM) + 2 worker (2vCPU, 8GB RAM)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Автоматическое создание ВМ для HA-кластера Kubernetes (kubespray) ===${NC}"
echo ""
echo -e "${YELLOW}Будут созданы:${NC}"
echo "  - 3 master-ноды: k8s-ha-master-1, k8s-ha-master-2, k8s-ha-master-3"
echo "  - 2 worker-ноды: k8s-ha-worker-1, k8s-ha-worker-2"
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

# Автоматическое определение параметров
echo "Автоматическое определение параметров..."

# Folder ID
FOLDER_ID=$(yc config get folder-id 2>/dev/null || echo "")
if [ -z "$FOLDER_ID" ]; then
    echo -e "${RED}Ошибка: Folder ID не найден. Выполните: yc config set folder-id <folder-id>${NC}"
    exit 1
fi
echo "  Folder ID: $FOLDER_ID"

# Subnet ID и Zone
echo "  Поиск подсети..."
SUBNET_ID=$(yc vpc subnet list --format json 2>/dev/null | jq -r '.[0].id // empty')
if [ -z "$SUBNET_ID" ]; then
    echo -e "${RED}Ошибка: Подсеть не найдена. Создайте подсеть вручную.${NC}"
    exit 1
fi

# Определяем зону подсети
SUBNET_ZONE=$(yc vpc subnet get "$SUBNET_ID" --format json 2>/dev/null | jq -r '.zone_id // empty')
if [ -n "$SUBNET_ZONE" ]; then
    ZONE="$SUBNET_ZONE"
    echo "  Зона определена из подсети: $ZONE"
else
    ZONE=${ZONE:-ru-central1-a}
    echo "  Zone: $ZONE (по умолчанию)"
fi

SUBNET_NAME=$(yc vpc subnet list --format json 2>/dev/null | jq -r ".[] | select(.id == \"$SUBNET_ID\") | .name")
echo "  Подсеть: $SUBNET_NAME ($SUBNET_ID)"

# Image ID
echo "  Поиск образа Ubuntu..."
IMAGE_ID=$(yc compute image list --folder-id standard-images --format json 2>/dev/null | \
    jq -r '.[] | select(.family != null and (.family | contains("ubuntu-22") or contains("ubuntu-2204"))) | .id' | head -1)

if [ -z "$IMAGE_ID" ]; then
    IMAGE_ID=$(yc compute image list --folder-id standard-images --format json 2>/dev/null | \
        jq -r '.[] | select(.family != null and (.family | contains("ubuntu-20") or contains("ubuntu-2004"))) | .id' | head -1)
fi

if [ -z "$IMAGE_ID" ]; then
    echo -e "${RED}Ошибка: Образ Ubuntu не найден${NC}"
    exit 1
fi
IMAGE_NAME=$(yc compute image list --folder-id standard-images --format json 2>/dev/null | \
    jq -r ".[] | select(.id == \"$IMAGE_ID\") | .family // .name")
echo "  Образ: $IMAGE_NAME ($IMAGE_ID)"

# SSH Key
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SSH_KEY_PATH="${SSH_KEY_PATH:-$PROJECT_DIR/k8s-key.pub}"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${YELLOW}SSH ключ не найден, создаю новый...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$PROJECT_DIR/k8s-key" -N "" -C "k8s-ha-cluster-key"
    SSH_KEY_PATH="$PROJECT_DIR/k8s-key.pub"
fi
SSH_KEY=$(cat "$SSH_KEY_PATH")
echo "  SSH ключ: $SSH_KEY_PATH"

echo ""
echo -e "${GREEN}Параметры создания:${NC}"
echo "  Folder ID: $FOLDER_ID"
echo "  Zone: $ZONE"
echo "  Subnet ID: $SUBNET_ID"
echo "  Image ID: $IMAGE_ID"
echo "  SSH Key: $SSH_KEY_PATH"
echo ""

# Функция создания cloud-init конфигурации
create_user_data() {
    local USERNAME=$1
    local PASSWORD=$2
    local SSH_PUB_KEY=$3
    
    cat <<EOF
#cloud-config
users:
  - name: $USERNAME
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    ssh_authorized_keys:
      - $SSH_PUB_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']

ssh_pwauth: true
disable_root: false

chpasswd:
  list: |
    $USERNAME:$PASSWORD
  expire: false

package_update: true
package_upgrade: true

ssh_authorized_keys:
  - $SSH_PUB_KEY

runcmd:
  - echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME
  - chmod 0440 /etc/sudoers.d/$USERNAME
  - sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config || sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config || true
  - systemctl restart sshd || service ssh restart || true
EOF
}

# Функция создания ВМ
create_vm() {
    local VM_NAME=$1
    local VM_ROLE=$2
    local CPU=$3
    local MEMORY=$4
    local USERNAME=$5
    local PASSWORD=$6
    
    echo ""
    echo -e "${GREEN}Создание ВМ: $VM_NAME ($VM_ROLE)${NC}"
    echo "  Пользователь: $USERNAME"
    
    # Проверка, не существует ли уже ВМ с таким именем
    if yc compute instance get "$VM_NAME" &>/dev/null; then
        echo -e "${YELLOW}⚠ ВМ $VM_NAME уже существует, пропускаем...${NC}"
        VM_IP=$(yc compute instance get "$VM_NAME" --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address // "N/A"')
        VM_INT_IP=$(yc compute instance get "$VM_NAME" --format json | jq -r '.network_interfaces[0].primary_v4_address.address')
        echo "  External IP: $VM_IP"
        echo "  Internal IP: $VM_INT_IP"
        echo "$VM_NAME,$VM_IP,$VM_INT_IP,$USERNAME,$PASSWORD" >> /tmp/k8s-ha-vms.csv
        return 0
    fi
    
    # Создание cloud-init конфигурации
    USER_DATA_FILE="/tmp/${VM_NAME}-user-data.yaml"
    create_user_data "$USERNAME" "$PASSWORD" "$SSH_KEY" > "$USER_DATA_FILE"
    
    # Создание ВМ
    if yc compute instance create \
        --name "$VM_NAME" \
        --folder-id "$FOLDER_ID" \
        --zone "$ZONE" \
        --network-interface subnet-id="$SUBNET_ID",nat-ip-version=ipv4 \
        --create-boot-disk image-id="$IMAGE_ID",size=20 \
        --cores "$CPU" \
        --memory "${MEMORY}GB" \
        --metadata-from-file user-data="$USER_DATA_FILE" \
        --metadata-from-file ssh-keys=/dev/stdin <<< "$SSH_KEY" \
        --platform-id standard-v3 \
        --hostname "$VM_NAME" \
        --format json 2>/dev/null > /tmp/"$VM_NAME".json; then
        
        # Ждем немного, чтобы ВМ полностью создалась
        sleep 2
        
        # Получаем информацию о ВМ еще раз для получения IP
        VM_IP=$(yc compute instance get "$VM_NAME" --format json 2>/dev/null | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address // "N/A"')
        VM_INT_IP=$(yc compute instance get "$VM_NAME" --format json 2>/dev/null | jq -r '.network_interfaces[0].primary_v4_address.address // "N/A"')
        
        echo -e "${GREEN}✓ ВМ $VM_NAME создана${NC}"
        echo "  External IP: $VM_IP"
        echo "  Internal IP: $VM_INT_IP"
        echo "  Пользователь: $USERNAME"
        echo "  Пароль: $PASSWORD"
        echo "$VM_NAME,$VM_IP,$VM_INT_IP,$USERNAME,$PASSWORD" >> /tmp/k8s-ha-vms.csv
        
        # Удаление временного файла
        rm -f "$USER_DATA_FILE"
    else
        echo -e "${RED}✗ Ошибка при создании ВМ $VM_NAME${NC}"
        if [ -f /tmp/"$VM_NAME".json ]; then
            cat /tmp/"$VM_NAME".json
        fi
        rm -f "$USER_DATA_FILE"
        return 1
    fi
}

# Создание файла для хранения информации о ВМ
echo "VM_NAME,EXTERNAL_IP,INTERNAL_IP,USERNAME,PASSWORD" > /tmp/k8s-ha-vms.csv

# Создание 3 master-нод для HA кластера
create_vm "k8s-ha-master-1" "master" 2 8 "master1" "master1"
create_vm "k8s-ha-master-2" "master" 2 8 "master2" "master2"
create_vm "k8s-ha-master-3" "master" 2 8 "master3" "master3"

# Создание 2 worker-нод для HA кластера
create_vm "k8s-ha-worker-1" "worker" 2 8 "worker1" "worker1"
create_vm "k8s-ha-worker-2" "worker" 2 8 "worker2" "worker2"

echo ""
echo -e "${GREEN}=== Все ВМ для HA кластера созданы ===${NC}"
echo ""
echo "Список созданных ВМ:"
echo "===================="
cat /tmp/k8s-ha-vms.csv | column -t -s',' 2>/dev/null || cat /tmp/k8s-ha-vms.csv
echo ""

# Сохранение информации в файл проекта
if [ -d "$PROJECT_DIR/kubespray" ]; then
    cp /tmp/k8s-ha-vms.csv "$PROJECT_DIR/kubespray/vms-ha-info.txt" 2>/dev/null || true
    echo "Информация сохранена в: $PROJECT_DIR/kubespray/vms-ha-info.txt"
fi

echo ""
echo -e "${YELLOW}Учетные данные для подключения:${NC}"
echo "Master nodes:"
echo "  ssh -i $PROJECT_DIR/k8s-key master1@<MASTER1_IP> (пароль: master1)"
echo "  ssh -i $PROJECT_DIR/k8s-key master2@<MASTER2_IP> (пароль: master2)"
echo "  ssh -i $PROJECT_DIR/k8s-key master3@<MASTER3_IP> (пароль: master3)"
echo ""
echo "Worker nodes:"
echo "  ssh -i $PROJECT_DIR/k8s-key worker1@<WORKER1_IP> (пароль: worker1)"
echo "  ssh -i $PROJECT_DIR/k8s-key worker2@<WORKER2_IP> (пароль: worker2)"
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Подождите 1-2 минуты для полной инициализации ВМ"
echo "2. Проверьте доступность ВМ: ping <EXTERNAL_IP>"
echo "3. Подключитесь к ВМ используя учетные данные выше"
echo "4. Следуйте инструкциям в kubespray/DEPLOY_HA_CLUSTER.md для развертывания кластера"
