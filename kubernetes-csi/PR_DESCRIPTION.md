# ДЗ 12: Установка и использование CSI драйвера для S3 Object Storage

## 📋 Описание

Реализовано домашнее задание по установке и настройке CSI (Container Storage Interface) драйвера для S3 Object Storage в managed Kubernetes кластере Yandex Cloud. Драйвер позволяет монтировать S3 buckets как PersistentVolumes в Kubernetes поды.

## ✅ Выполненные задачи

### 1. Подготовка инфраструктуры
- ✅ Использован существующий managed Kubernetes cluster `test-k8s` (3 ноды, v1.32.1)
- ✅ Создан S3 bucket `csi-s3-bucket-konstsima` в Yandex Cloud Object Storage
- ✅ Создан ServiceAccount `csi-s3-sa` с ролью `storage.editor`
- ✅ Сгенерированы статические ключи доступа (Access Key ID и Secret Access Key)

### 2. Установка CSI драйвера
- ✅ Установлен CSI driver `ru.yandex.s3.csi` через Helm из официального репозитория Yandex Cloud
- ✅ CSI driver развернут в namespace `kube-system`
- ✅ Проверена работоспособность CSI controller и node pods

### 3. Создание Kubernetes ресурсов
- ✅ Создан Secret `csi-s3-secret` в namespace `kube-system` с ключами доступа к Object Storage
- ✅ Создан StorageClass `csi-s3` с настройками:
  - Provisioner: `ru.yandex.s3.csi`
  - Mounter: `geesefs` (рекомендуемый для Yandex Cloud)
  - Bucket: `csi-s3-bucket-konstsima`
  - Опции монтирования: `--memory-limit 1000 --dir-mode 0777 --file-mode 0666`
  - AutoProvisioning: включен через параметр `bucket`
- ✅ Создан PVC `s3-pvc` с использованием StorageClass
- ✅ Создан тестовый Pod `s3-test-pod`, который монтирует PVC и записывает данные

### 4. Тестирование и проверка
- ✅ Проверена работа PVC (статус: Bound)
- ✅ Проверена работа пода (статус: Running)
- ✅ Проверена запись файлов в монтированный volume
- ✅ Проверено сохранение файлов в S3 Object Storage
- ✅ Создан тестовый Deployment для демонстрации использования

## 📁 Структура добавленных файлов

### Kubernetes манифесты
- **`s3-secret-kube-system.yaml`** - Secret с ключами доступа к Object Storage (namespace: kube-system)
- **`s3-storageclass.yaml`** - StorageClass для S3 с настройками autoProvisioning и geesefs
- **`s3-pvc.yaml`** - PersistentVolumeClaim с использованием StorageClass
- **`s3-test-pod.yaml`** - Тестовый Pod, монтирующий PVC и записывающий данные в `/mnt/s3`
- **`s3-test-deployment.yaml`** - Тестовый Deployment для демонстрации использования PVC

### Документация
- **`README.md`** - Описание проекта, структуры файлов и быстрый старт
- **`INSTALLATION.md`** - Подробная пошаговая инструкция выполнения всех шагов домашнего задания

## 🔧 Технические детали

### Конфигурация StorageClass
```yaml
provisioner: ru.yandex.s3.csi
parameters:
  mounter: geesefs
  options: "--memory-limit 1000 --dir-mode 0777 --file-mode 0666"
  bucket: "csi-s3-bucket-konstsima"
```

### Особенности реализации
1. **GeeseFS вместо s3fs**: Выбран geesefs как рекомендуемый mounter для Yandex Cloud, обеспечивающий лучшую производительность и POSIX-совместимость
2. **AutoProvisioning**: Настроен через параметр `bucket` в StorageClass, что позволяет автоматически создавать префиксы для каждого PVC в одном bucket
3. **Правильные ссылки на Secret**: Все необходимые CSI secret references настроены для всех операций (provisioner, controller-publish, node-stage, node-publish)

### Информация о ресурсах
- **Кластер**: test-k8s (managed Kubernetes в Yandex Cloud)
- **Ноды**: 3 ноды (v1.32.1)
- **S3 Bucket**: csi-s3-bucket-konstsima
- **ServiceAccount**: csi-s3-sa (ID: aje2ijcfvso2qa6fnkgh)
- **Secret**: csi-s3-secret (namespace: kube-system)
- **StorageClass**: csi-s3

## 🚀 Быстрый старт

1. **Установка CSI driver:**
```bash
helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts
helm repo update
helm install csi-s3 yandex-s3/csi-s3 \
  --namespace kube-system \
  --set secret.accessKey='<ACCESS_KEY>' \
  --set secret.secretKey='<SECRET_KEY>' \
  --set storageClass.create=false
```

2. **Применение манифестов:**
```bash
kubectl apply -f s3-secret-kube-system.yaml
kubectl apply -f s3-storageclass.yaml
kubectl apply -f s3-pvc.yaml
kubectl apply -f s3-test-pod.yaml
```

3. **Проверка:**
```bash
kubectl get pvc s3-pvc
kubectl get pods
kubectl logs s3-test-pod
kubectl exec s3-test-pod -- ls -la /mnt/s3/
```

## ✨ Результаты тестирования

- ✅ PVC успешно создается и переходит в статус `Bound`
- ✅ Pod успешно монтирует volume и запускается
- ✅ Файлы записываются в монтированный volume (`/mnt/s3`)
- ✅ Данные сохраняются в S3 Object Storage (проверено через volumeHandle в PV)
- ✅ Все компоненты работают стабильно

## 📚 Дополнительная информация

Подробная пошаговая инструкция выполнения задания находится в файле [INSTALLATION.md](INSTALLATION.md), включая:
- Развертывание Kubernetes кластера
- Создание S3 bucket и ServiceAccount
- Установку CSI driver различными способами
- Создание и настройку всех необходимых ресурсов
- Устранение неполадок

## 🔗 Полезные ссылки

- [Официальная документация Yandex Cloud CSI-S3](https://cloud.yandex.ru/docs/managed-kubernetes/operations/applications/csi-s3)
- [GitHub репозиторий k8s-csi-s3](https://github.com/yandex-cloud/k8s-csi-s3)
- [Документация GeeseFS](https://cloud.yandex.ru/docs/storage/tools/geesefs)
