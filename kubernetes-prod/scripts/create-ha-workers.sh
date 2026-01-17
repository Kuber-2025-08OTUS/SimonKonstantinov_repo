#!/bin/bash
# Скрипт для создания оставшихся worker-нод для HA кластера

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Параметры (такие же как в create-vms-ha.sh)
FOLDER_ID=$(yc config get folder-id 2>/dev/null || echo "")
SUBNET_ID=$(yc vpc subnet list --format json 2>/dev/null | jq -r '.[0].id // empty')
SUBNET_ZONE=$(yc vpc subnet get "$SUBNET_ID" --format json 2>/dev/null | jq -r '.zone_id // empty')
ZONE=${SUBNET_ZONE:-ru-central1-a}
IMAGE_ID=$(yc compute image list --folder-id standard-images --format json 2>/dev/null | \
    jq -r '.[] | select(.family != null and (.family | contains("ubuntu-22") or contains("ubuntu-2204"))) | .id' | head -1)
SSH_KEY_PATH="${SSH_KEY_PATH:-$PROJECT_DIR/k8s-key.pub}"
SSH_KEY=$(cat "$SSH_KEY_PATH")

# Функции из create-vms-ha.sh
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

create_vm() {
    local VM_NAME=$1
    local USERNAME=$2
    local PASSWORD=$3
    
    echo "Создание ВМ: $VM_NAME"
    
    if yc compute instance get "$VM_NAME" &>/dev/null; then
        echo "⚠ ВМ $VM_NAME уже существует, пропускаем..."
        return 0
    fi
    
    USER_DATA_FILE="/tmp/${VM_NAME}-user-data.yaml"
    create_user_data "$USERNAME" "$PASSWORD" "$SSH_KEY" > "$USER_DATA_FILE"
    
    yc compute instance create \
        --name "$VM_NAME" \
        --folder-id "$FOLDER_ID" \
        --zone "$ZONE" \
        --network-interface subnet-id="$SUBNET_ID",nat-ip-version=ipv4 \
        --create-boot-disk image-id="$IMAGE_ID",size=20 \
        --cores 2 \
        --memory 8GB \
        --metadata-from-file user-data="$USER_DATA_FILE" \
        --metadata-from-file ssh-keys=/dev/stdin <<< "$SSH_KEY" \
        --platform-id standard-v3 \
        --hostname "$VM_NAME" \
        --format json 2>/dev/null > /tmp/"$VM_NAME".json || {
        echo "Ошибка при создании $VM_NAME"
        cat /tmp/"$VM_NAME".json 2>/dev/null || true
        rm -f "$USER_DATA_FILE"
        return 1
    }
    
    sleep 2
    VM_IP=$(yc compute instance get "$VM_NAME" --format json 2>/dev/null | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address // "N/A"')
    VM_INT_IP=$(yc compute instance get "$VM_NAME" --format json 2>/dev/null | jq -r '.network_interfaces[0].primary_v4_address.address // "N/A"')
    echo "✓ ВМ $VM_NAME создана: External=$VM_IP, Internal=$VM_INT_IP"
    rm -f "$USER_DATA_FILE"
}

# Создаем оставшиеся worker-ноды
create_vm "k8s-ha-worker-1" "worker1" "worker1"
create_vm "k8s-ha-worker-2" "worker2" "worker2"

echo ""
echo "Проверка созданных ВМ:"
yc compute instance list --format json 2>/dev/null | jq -r '.[] | select(.name | startswith("k8s-ha")) | "\(.name): \(.network_interfaces[0].primary_v4_address.one_to_one_nat.address // "N/A")"'
