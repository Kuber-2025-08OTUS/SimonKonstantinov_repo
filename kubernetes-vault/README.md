# ДЗ 11: Хранилище секретов для приложения. Vault

## Описание
Установка Hashicorp Vault в HA режиме с Consul бэкендом и настройка External Secrets Operator для автоматической синхронизации секретов.

## Структура файлов
- `consul-values.yaml` - значения для установки Consul
- `vault-values.yaml` - значения для установки Vault
- `vault-auth-sa.yaml` - ServiceAccount и ClusterRoleBinding для авторизации
- `vault-policy.hcl` - политика доступа к секретам
- `secretstore.yaml` - манифест SecretStore для External Secrets Operator
- `externalsecret.yaml` - манифест ExternalSecret для синхронизации секрета

## Выполненные шаги
1. ✅ Создана папка kubernetes-vault
2. ✅ Установлен Consul в namespace consul (3 реплики)
3. ✅ Установлен Vault в namespace vault в HA режиме с Consul бэкендом
4. ✅ Инициализирован Vault и распечатаны все поды
5. ✅ Создано хранилище секретов otus/ с KV Secret Engine и секретом otus/cred
6. ✅ Создан ServiceAccount vault-auth и ClusterRoleBinding для авторизации Kubernetes
7. ✅ Настроена авторизация auth/kubernetes в Vault
8. ✅ Создана политика otus-policy и роль auth/kubernetes/role/otus
9. ✅ Установлен External Secrets Operator в namespace vault
10. ✅ Создан SecretStore для доступа к Vault KV секретам
11. ✅ Создан ExternalSecret и синхронизирован секрет otus/cred в Kubernetes Secret otus-cred
