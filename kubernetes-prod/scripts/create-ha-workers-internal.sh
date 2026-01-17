#!/bin/bash
# Скрипт для создания worker-нод для HA кластера БЕЗ внешних IP
# (используется, когда исчерпан лимит внешних IP-адресов)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Параметры
FOLDER_ID=$(yc config get folder-id 2>/dev/null || echo "")
SUBNET_ID=$(yc vpc subnet list --format json 2>/dev/null | jq -r '.[0].id // empty')
SUBNET_ZONE=$(yc vpc subnet get "$SUBNET_ID" --format json 2>/dev/null | jq -r '.zone_id // empty')
ZONE=${SUBNET_ZONE:-ru-central1-a}
IMAGE_ID=$(yc compute image list --folder-id standard-images --format json 2>/dev/null | \
    jq -r '.[] | select(.family != null and (.family | contains("ubuntu-22") or contains("ubuntu-2204"))) | .id' | head -1)
SSH_KEY_PATH="${SSH_KEY_PATH:-$PROJECT_DIR/k8s-key.pub}"
SSH_KEY=$(cat "$SSH_KEY_PATH")

echo "Создание worker-нод БЕЗ внешних IP (только Internal IP)"
echo "Подключение будет через существующую ВМ в облаке (например, k8s-learning-vm)"
echo ""

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

create_vm_internal() {
    local VM_NAME=$1
    local USERNAME=$2
    local PASSWORD=$3
    
    echo "Создание ВМ: $VM_NAME (только Internal IP)"
    
    if yc compute instance get "$VM_NAME" &>/dev/null; then
        VM_INT_IP=$(yc compute instance get "$VM_NAME" --format json | jq -r '.network_interfaces[0].primary_v4_address.address')
        echo "⚠ ВМ $VM_NAME уже существует, Internal IP: $VM_INT_IP"
        echo "$VM_NAME,N/A,$VM_INT_IP,$USERNAME,$PASSWORD" >> /tmp/k8s-ha-vms.csv
        return 0
    fi
    
    USER_DATA_FILE="/tmp/${VM_NAME}-user-data.yaml"
    create_user_data "$USERNAME" "$PASSWORD" "$SSH_KEY" > "$USER_DATA_FILE"
    
    # Создание БЕЗ внешнего IP (без nat-ip-version=ipv4)
    if yc compute instance create \
        --name "$VM_NAME" \
        --folder-id "$FOLDER_ID" \
        --zone "$ZONE" \
        --network-interface subnet-id="$SUBNET_ID" \
        --create-boot-disk image-id="$IMAGE_ID",size=20 \
        --cores 2 \
        --memory 8GB \
        --metadata-from-file user-data="$USER_DATA_FILE" \
        --metadata-from-file ssh-keys=/dev/stdin <<< "$SSH_KEY" \
        --platform-id standard-v3 \
        --hostname "$VM_NAME" \
        --format json 2>/dev/null > /tmp/"$VM_NAME".json; then
        
        sleep 2
        VM_INT_IP=$(yc compute instance get "$VM_NAME" --format json 2>/dev/null | jq -r '.network_interfaces[0].primary_v4_address.address // "N/A"')
        echo "✓ ВМ $VM_NAME создана: Internal IP=$VM_INT_IP"
        echo "$VM_NAME,N/A,$VM_INT_IP,$USERNAME,$PASSWORD" >> /tmp/k8s-ha-vms.csv
        rm -f "$USER_DATA_FILE"
    else
        echo "✗ Ошибка при создании $VM_NAME"
        cat /tmp/"$VM_NAME".json 2>/dev/null || true
        rm -f "$USER_DATA_FILE"
        return 1
    fi
}

# Создание файла для хранения информации о ВМ
echo "VM_NAME,EXTERNAL_IP,INTERNAL_IP,USERNAME,PASSWORD" > /tmp/k8s-ha-vms.csv

# Добавляем существующие master-ноды
echo "k8s-ha-master-1,84.201.154.86,10.129.0.5,master1,master1" >> /tmp/k8s-ha-vms.csv
echo "k8s-ha-master-2,89.169.170.173,10.129.0.9,master2,master2" >> /tmp/k8s-ha-vms.csv
echo "k8s-ha-master-3,89.169.189.72,10.129.0.8,master3,master3" >> /tmp/k8s-ha-vms.csv

# Создаем worker-ноды БЕЗ внешних IP
create_vm_internal "k8s-ha-worker-1" "worker1" "worker1"
create_vm_internal "k8s-ha-worker-2" "worker2" "worker2"

echo ""
echo "=== Все ВМ для HA кластера ==="
cat /tmp/k8s-ha-vms.csv | column -t -s',' 2>/dev/null || cat /tmp/k8s-ha-vms.csv

# Сохранение в файл проекта
if [ -d "$PROJECT_DIR/kubespray" ]; then
    cp /tmp/k8s-ha-vms.csv "$PROJECT_DIR/kubespray/vms-ha-info.txt" 2>/dev/null || true
    echo ""
    echo "Информация сохранена в: $PROJECT_DIR/kubespray/vms-ha-info.txt"
fi

echo ""
echo "ВАЖНО:"
echo "- Worker-ноды созданы БЕЗ внешних IP (только Internal IP)"
echo "- Для подключения используйте существующую ВМ в облаке (например, k8s-learning-vm)"
echo "- Или подключитесь через VPN/бастион к подсети"
echo "- В inventory файле используйте Internal IP для worker-нод"
