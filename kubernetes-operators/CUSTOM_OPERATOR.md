# Свой MySQL Operator на Python (Kopf)

## Описание

Реализован собственный Kubernetes оператор на Python с использованием фреймворка Kopf для управления MySQL инстансами.

## Функциональность

### При создании MySQL инстанса:
1. **PersistentVolume (PV)** - хранилище заданного размера
2. **PersistentVolumeClaim (PVC)** - заявка на хранилище
3. **Service** - для доступа к MySQL (port 3306)
4. **Deployment** - с контейнером MySQL

### При удалении MySQL инстанса:
- Удаляются все созданные ресурсы (PV, PVC, Service, Deployment)

## Структура кода

```
@kopf.on.event('otus.homework', 'v1', 'mysqls')
def mysql_handler(event, **kwargs):
    # Обработчик событий для MySQL CRD
    # ADDED/MODIFIED -> create_mysql_resources()
    # DELETED -> delete_mysql_resources()
```

## Функции оператора

- `create_mysql_resources()` - создание всех ресурсов
- `delete_mysql_resources()` - удаление всех ресурсов
- `create_pv()` - создание PersistentVolume
- `create_pvc()` - создание PersistentVolumeClaim
- `create_service()` - создание Service
- `create_deployment()` - создание Deployment

## Использование

### Сборка Docker образа
```
docker build -t mysql-operator-custom:latest .
```

### Развертывание оператора
```
kubectl apply -f mysql-crd.yaml
kubectl apply -f mysql-operator-sa.yaml
kubectl apply -f mysql-operator-role.yaml
kubectl apply -f mysql-operator-rolebinding.yaml
kubectl apply -f mysql-operator-custom-deployment.yaml
```

### Создание MySQL инстанса
```
kubectl apply -f mysql-instance.yaml
kubectl get mysqls
kubectl get deployments,services,pv,pvc
```

### Удаление MySQL инстанса
```
kubectl delete mysql mysql-test
```

## Параметры MySQL CRD

- `image` - Docker образ MySQL (default: mysql:5.7)
- `database` - имя базы данных
- `password` - пароль root
- `storage_size` - размер хранилища (e.g., 1Gi, 10Gi)

## Особенности

✅ Обработка ошибок (404 при удалении несуществующих ресурсов)
✅ Логирование всех операций
✅ Поддержка multiple namespaces
✅ Автоматическое управление жизненным циклом ресурсов
✅ Использование owner references (опционально через Kopf)
