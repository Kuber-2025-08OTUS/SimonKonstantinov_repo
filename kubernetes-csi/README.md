# ДЗ 12: Установка и использование CSI драйвера

## Описание
Задание по установке и настройке CSI (Container Storage Interface) драйвера для S3 Object Storage в Kubernetes кластере Yandex Cloud.

## Выполненные шаги
1. ✅ Создана папка kubernetes-csi
2. ✅ Проверен managed Kubernetes cluster в Yandex Cloud (3 ноды)
3. ✅ Создан S3 bucket `csi-s3-bucket-konstsima` в Yandex Cloud Object Storage
4. ✅ Создан ServiceAccount `csi-s3-sa` в Yandex Cloud с правами `storage.editor`
5. ✅ Сгенерированы ключи доступа (Access Key ID и Secret Access Key)
6. ✅ Создан Kubernetes Secret `csi-s3-secret` с ключами доступа к Object Storage
7. ✅ Создан StorageClass `csi-s3` для работы с S3 bucket
8. ✅ Подготовлены манифесты для установки CSI драйвера
9. ✅ Создан PVC с autoProvisioning
10. ✅ Созданы тестовые Pod и Deployment для проверки работы

## Информация о ресурсах
- **Кластер**: test-k8s (managed Kubernetes в Yandex Cloud)
- **Ноды**: 3 ноды (v1.32.1)
- **S3 Bucket**: csi-s3-bucket-konstsima
- **Bucket ID**: e3e4ugufnuobm1bib6pb
- **ServiceAccount**: csi-s3-sa (ID: aje2ijcfvso2qa6fnkgh)
- **Access Key ID**: `<ACCESS_KEY_ID>` (замените на ваш ключ)
- **Secret**: csi-s3-secret (namespace: kube-system)
- **StorageClass**: csi-s3
- **Provisioner**: ru.yandex.s3.csi
- **Mounter**: geesefs

## Структура файлов

### Манифесты для проверки ДЗ
- `s3-secret-kube-system.yaml` - Secret с ключами доступа к Object Storage (namespace: kube-system)
- `s3-storageclass.yaml` - StorageClass для S3 с настройками autoProvisioning
- `s3-pvc.yaml` - PersistentVolumeClaim с использованием StorageClass
- `s3-test-pod.yaml` - Тестовый Pod, использующий PVC и записывающий данные в S3
- `s3-test-deployment.yaml` - Тестовый Deployment, использующий PVC

### Документация
- `INSTALLATION.md` - Подробная пошаговая инструкция выполнения домашнего задания
- `README.md` - Описание проекта и структуры файлов

### Дополнительные файлы
- `s3-secret.yaml` - Secret для namespace default (для справки, не используется CSI driver)
- `ДЗ_12___установка_и_использование_CSI_драйвера-516699-9deef1.pdf` - Задание в формате PDF

## Быстрый старт

1. **Установка CSI driver через Helm:**
```bash
helm repo add yandex-s3 https://yandex-cloud.github.io/k8s-csi-s3/charts
helm repo update
helm install csi-s3 yandex-s3/csi-s3 \
  --namespace kube-system \
  --set secret.accessKey='<ACCESS_KEY_ID>' \
  --set secret.secretKey='<SECRET_ACCESS_KEY>' \
  --set storageClass.create=false
```

2. **Применение манифестов:**
```bash
# Secret для kube-system
kubectl apply -f s3-secret-kube-system.yaml

# StorageClass
kubectl apply -f s3-storageclass.yaml

# PVC
kubectl apply -f s3-pvc.yaml

# Тестовый Pod
kubectl apply -f s3-test-pod.yaml
```

3. **Проверка работы:**
```bash
# Проверка PVC
kubectl get pvc s3-pvc

# Проверка Pod
kubectl get pods
kubectl logs s3-test-pod

# Проверка файлов в S3
yc storage object list --bucket-name csi-s3-bucket-konstsima
```

## Подробная инструкция

См. файл [INSTALLATION.md](INSTALLATION.md) для подробной пошаговой инструкции выполнения всех шагов домашнего задания.

## Параметры StorageClass

- **Provisioner**: `ru.yandex.s3.csi` - CSI driver от Yandex Cloud
- **Mounter**: `geesefs` - файловая система для монтирования S3
- **Bucket**: `csi-s3-bucket-konstsima` - используемый S3 bucket
- **Reclaim Policy**: `Delete` - автоматическое удаление при удалении PVC
- **Volume Binding Mode**: `Immediate` - немедленное связывание volume

## Проверка записи в ObjectStorage

После запуска пода файлы должны появиться в S3 bucket. Проверьте:
1. Через Yandex Cloud Console → Object Storage → csi-s3-bucket-konstsima
2. Через YC CLI: `yc storage object list --bucket-name csi-s3-bucket-konstsima`
3. Через под: `kubectl exec -it s3-test-pod -- ls -la /mnt/s3/`
