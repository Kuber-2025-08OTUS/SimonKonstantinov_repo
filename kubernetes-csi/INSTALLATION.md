# Пошаговая инструкция выполнения домашнего задания

## Требования
- Управляемый Kubernetes кластер в Yandex Cloud
- `kubectl` настроен для работы с кластером
- `helm` версии 3.8.0 или новее
- Доступ к Yandex Cloud Console или YC CLI

---

## Шаг 1: Развертывание Managed Kubernetes кластера

### Вариант A: Через Yandex Cloud Console
1. Откройте [Yandex Cloud Console](https://console.cloud.yandex.ru/)
2. Перейдите в раздел **Managed Service for Kubernetes**
3. Нажмите **Создать кластер**
4. Заполните параметры:
   - Имя кластера: `test-k8s` (или любое другое)
   - Версия Kubernetes: последняя стабильная
   - Количество нод: минимум 1 (рекомендуется 3)
   - Конфигурация нод: любая подходящая
5. Дождитесь создания кластера (обычно 5-10 минут)

### Вариант B: Через YC CLI
```bash
yc managed-kubernetes cluster create \
  --name test-k8s \
  --network-name default \
  --zone ru-central1-a \
  --subnet-name default-ru-central1-a \
  --service-account-name k8s-service-account \
  --node-service-account-name k8s-node-service-account \
  --public-ip
```

После создания кластера получите kubeconfig:
```bash
yc managed-kubernetes cluster get-credentials --id <cluster-id> --external
```

---

## Шаг 2: Создание S3 bucket в Object Storage

### Через Yandex Cloud Console
1. Перейдите в раздел **Object Storage**
2. Нажмите **Создать бакет**
3. Заполните параметры:
   - Имя бакета: `csi-s3-bucket-konstsima` (должно быть уникальным)
   - Тип доступа: **Приватный**
   - Регион: `ru-central1`
4. Сохраните бакет

### Через YC CLI
```bash
yc storage bucket create \
  --name csi-s3-bucket-konstsima \
  --default-storage-class standard
```

---

## Шаг 3: Создание ServiceAccount и генерация ключей доступа

### Создание ServiceAccount
```bash
yc iam service-account create --name csi-s3-sa
```

### Назначение прав доступа
ServiceAccount должен иметь роль `storage.editor`:
```bash
yc resource-manager folder add-access-binding <folder-id> \
  --role storage.editor \
  --subject serviceAccount:<service-account-id>
```

### Генерация статического ключа доступа
```bash
yc iam access-key create --service-account-name csi-s3-sa
```

Сохраните полученные значения:
- **Access Key ID** (например: `YCAJ...`)
- **Secret Access Key** (например: `YCPF...`)

---

## Шаг 4: Создание Secret с ключами доступа

Создайте Secret в namespace `kube-system` (это обязательно для CSI driver):

```bash
kubectl apply -f s3-secret-kube-system.yaml
```

Или создайте вручную:
```bash
kubectl create secret generic csi-s3-secret \
  --namespace kube-system \
  --from-literal=accessKeyID='<ACCESS_KEY_ID>' \
  --from-literal=secretAccessKey='<SECRET_ACCESS_KEY>' \
  --from-literal=endpoint='https://storage.yandexcloud.net' \
  --from-literal=region='ru-central1'
```

**Проверка:**
```bash
kubectl get secret csi-s3-secret -n kube-system
```

---

## Шаг 5: Создание StorageClass

Примените манифест StorageClass:
```bash
kubectl apply -f s3-storageclass.yaml
```

**Проверка:**
```bash
kubectl get storageclass csi-s3
```

---

## Шаг 6: Установка CSI driver

### Вариант A: Через Helm (рекомендуется)

#### Установка из GitHub репозитория (самый актуальный)
```bash
# Добавление репозитория
helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts
helm repo update

# Установка CSI driver
helm install csi-s3 yandex-s3/csi-s3 \
  --namespace kube-system \
  --set secret.accessKey='<ACCESS_KEY_ID>' \
  --set secret.secretKey='<SECRET_ACCESS_KEY>' \
  --set secret.endpoint='https://storage.yandexcloud.net' \
  --set storageClass.create=false \
  --set storageClass.singleBucket='csi-s3-bucket-konstsima'
```

#### Или установка из Marketplace
```bash
helm pull oci://cr.yandex/yc-marketplace/yandex-cloud/csi-s3/csi-s3 \
  --version 0.43.0 \
  --untar

helm install csi-s3 ./csi-s3/ \
  --namespace kube-system \
  --set secret.accessKey='<ACCESS_KEY_ID>' \
  --set secret.secretKey='<SECRET_ACCESS_KEY>' \
  --set storageClass.create=false
```

### Вариант B: Через Yandex Cloud Marketplace (веб-интерфейс)
1. Откройте ваш Kubernetes кластер в Yandex Cloud Console
2. Перейдите на вкладку **Marketplace**
3. Найдите **Container Storage Interface for S3**
4. Нажмите **Установить**
5. Заполните параметры:
   - Namespace: `kube-system`
   - Application name: `csi-s3`
   - Create storage class: **Нет** (мы создали вручную)
   - Create secret: **Нет** (мы создали вручную)
   - S3 key ID: ваш Access Key ID
   - S3 secret key: ваш Secret Access Key
   - General S3 bucket: `csi-s3-bucket-konstsima`
   - S3 service address: `https://storage.yandexcloud.net`
6. Нажмите **Установить**

**Проверка установки:**
```bash
# Проверка подов CSI driver
kubectl get pods -n kube-system | grep csi-s3

# Должны быть запущены:
# - csi-s3-controller-*
# - csi-s3-node-*
```

---

## Шаг 7: Создание PVC с autoProvisioning

Примените манифест PVC:
```bash
kubectl apply -f s3-pvc.yaml
```

**Проверка:**
```bash
kubectl get pvc s3-pvc
kubectl describe pvc s3-pvc
```

PVC должен перейти в статус `Bound`. Если он остается в статусе `Pending`, проверьте логи CSI driver:
```bash
kubectl logs -n kube-system -l app=csi-s3-controller
```

---

## Шаг 8: Создание Pod/Deployment с использованием PVC

### Вариант A: Использование Pod
```bash
kubectl apply -f s3-test-pod.yaml
```

### Вариант B: Использование Deployment
```bash
kubectl apply -f s3-test-deployment.yaml
```

**Проверка:**
```bash
# Проверка статуса пода
kubectl get pods

# Просмотр логов
kubectl logs s3-test-pod

# Или для deployment
kubectl logs -l app=s3-test
```

---

## Шаг 9: Проверка записи файлов в ObjectStorage

### Проверка через Pod
```bash
# Подключиться к поду
kubectl exec -it s3-test-pod -- sh

# Проверить содержимое директории
ls -la /mnt/s3/

# Создать тестовый файл
echo "Test data from pod" > /mnt/s3/test-data.txt
cat /mnt/s3/test-data.txt
```

### Проверка через Yandex Cloud Console
1. Откройте ваш S3 bucket `csi-s3-bucket-konstsima`
2. Проверьте наличие файлов, созданных подом
3. Файлы должны быть видны в бакете

### Проверка через YC CLI
```bash
yc storage object list --bucket-name csi-s3-bucket-konstsima
```

---

## Устранение неполадок

### PVC остается в статусе Pending
```bash
# Проверьте события
kubectl describe pvc s3-pvc

# Проверьте логи CSI controller
kubectl logs -n kube-system -l app=csi-s3-controller

# Проверьте логи CSI node
kubectl logs -n kube-system -l app=csi-s3-node
```

### Pod не может смонтировать volume
```bash
# Проверьте события пода
kubectl describe pod s3-test-pod

# Проверьте, что CSI driver pods запущены
kubectl get pods -n kube-system | grep csi-s3
```

### Проблемы с правами доступа
- Убедитесь, что ServiceAccount имеет роль `storage.editor`
- Проверьте, что ключи доступа правильные
- Убедитесь, что Secret создан в namespace `kube-system`

---

## Манифесты для проверки ДЗ

Все необходимые манифесты находятся в репозитории:
- `s3-secret-kube-system.yaml` - Secret с ключами доступа
- `s3-storageclass.yaml` - StorageClass
- `s3-pvc.yaml` - PersistentVolumeClaim
- `s3-test-pod.yaml` - Тестовый Pod
- `s3-test-deployment.yaml` - Тестовый Deployment

---

## Дополнительная информация

- [Официальная документация Yandex Cloud CSI-S3](https://cloud.yandex.ru/docs/managed-kubernetes/operations/applications/csi-s3)
- [GitHub репозиторий k8s-csi-s3](https://github.com/yandex-cloud/k8s-csi-s3)
