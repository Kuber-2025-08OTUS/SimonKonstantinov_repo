# Ручное создание ВМ в Yandex Cloud

Если скрипт не работает, создайте ВМ вручную через веб-консоль или команды yc.

## Требования

- **Master-нода**: 1 узел, 2vCPU, 8GB RAM, 20GB диск
- **Worker-ноды**: 3 узла, 2vCPU, 8GB RAM, 20GB диск каждая

## Создание через веб-консоль

1. Откройте [Yandex Cloud Console](https://console.cloud.yandex.ru/)
2. Перейдите в раздел Compute Cloud → Виртуальные машины
3. Нажмите "Создать ВМ"

### Параметры для master-ноды:
- **Имя**: `k8s-master`
- **Зона доступности**: `ru-central1-a` (или другая)
- **Образ**: Ubuntu 22.04 LTS
- **Платформа**: Intel Ice Lake
- **vCPU**: 2
- **RAM**: 8 GB
- **Диск**: 20 GB (SSD)
- **Публичный IP**: Включить
- **SSH ключ**: Добавить ваш публичный ключ

### Параметры для worker-нод (повторить 3 раза):
- **Имя**: `k8s-worker-1`, `k8s-worker-2`, `k8s-worker-3`
- Остальные параметры такие же, как для master-ноды

## Создание через YC CLI (команды)

### 1. Получение необходимых параметров

```bash
# Получить Folder ID
yc config get folder-id

# Получить список образов Ubuntu
yc compute image list --folder-id standard-images | grep ubuntu

# Получить список подсетей
yc vpc subnet list
```

### 2. Создание master-ноды

```bash
# Замените значения на ваши
FOLDER_ID="<ваш-folder-id>"
ZONE="ru-central1-a"
SUBNET_ID="<ваш-subnet-id>"
IMAGE_ID="<ubuntu-image-id>"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

yc compute instance create \
  --name k8s-master \
  --folder-id "$FOLDER_ID" \
  --zone "$ZONE" \
  --network-interface subnet-id="$SUBNET_ID",nat-ip-version=ipv4 \
  --create-boot-disk image-id="$IMAGE_ID",size=20 \
  --cores 2 \
  --memory 8GB \
  --metadata-from-file ssh-keys=/dev/stdin <<< "$SSH_KEY" \
  --platform-id standard-v3 \
  --hostname k8s-master
```

### 3. Создание worker-нод

```bash
# Создание worker-1
yc compute instance create \
  --name k8s-worker-1 \
  --folder-id "$FOLDER_ID" \
  --zone "$ZONE" \
  --network-interface subnet-id="$SUBNET_ID",nat-ip-version=ipv4 \
  --create-boot-disk image-id="$IMAGE_ID",size=20 \
  --cores 2 \
  --memory 8GB \
  --metadata-from-file ssh-keys=/dev/stdin <<< "$SSH_KEY" \
  --platform-id standard-v3 \
  --hostname k8s-worker-1

# Создание worker-2
yc compute instance create \
  --name k8s-worker-2 \
  --folder-id "$FOLDER_ID" \
  --zone "$ZONE" \
  --network-interface subnet-id="$SUBNET_ID",nat-ip-version=ipv4 \
  --create-boot-disk image-id="$IMAGE_ID",size=20 \
  --cores 2 \
  --memory 8GB \
  --metadata-from-file ssh-keys=/dev/stdin <<< "$SSH_KEY" \
  --platform-id standard-v3 \
  --hostname k8s-worker-2

# Создание worker-3
yc compute instance create \
  --name k8s-worker-3 \
  --folder-id "$FOLDER_ID" \
  --zone "$ZONE" \
  --network-interface subnet-id="$SUBNET_ID",nat-ip-version=ipv4 \
  --create-boot-disk image-id="$IMAGE_ID",size=20 \
  --cores 2 \
  --memory 8GB \
  --metadata-from-file ssh-keys=/dev/stdin <<< "$SSH_KEY" \
  --platform-id standard-v3 \
  --hostname k8s-worker-3
```

## Проверка созданных ВМ

```bash
# Список всех ВМ
yc compute instance list

# Получение IP-адресов
yc compute instance list --format json | jq -r '.[] | "\(.name): \(.network_interfaces[0].primary_v4_address.one_to_one_nat.address // "N/A")"'

# Детальная информация о ВМ
yc compute instance get k8s-master
```

## Сохранение информации о ВМ

Создайте файл `vms-info.txt` с информацией о ВМ:

```bash
cat > vms-info.txt << EOF
Master node:
  Name: k8s-master
  External IP: <получить через yc compute instance get k8s-master>
  Internal IP: <получить через yc compute instance get k8s-master>

Worker nodes:
  k8s-worker-1: <IP>
  k8s-worker-2: <IP>
  k8s-worker-3: <IP>
EOF
```

## Следующие шаги

После создания ВМ:
1. Подождите 1-2 минуты для полной инициализации
2. Проверьте доступность: `ping <EXTERNAL_IP>`
3. Подключитесь: `ssh ubuntu@<EXTERNAL_IP>` (или другой пользователь в зависимости от образа)
4. Следуйте инструкциям в `commands/01-prepare-master.md` и `commands/02-prepare-worker.md`
