# Выполнено ДЗ № 11

 - [x] Основное ДЗ
 - [ ] Задание со *

## В процессе сделано:
 - Установлен Consul в namespace consul с 3 репликами сервера из helm-чарта
 - Установлен Vault в namespace vault в HA режиме (3 реплики) с Consul бэкендом из helm-чарта
 - Выполнена инициализация Vault и распечатаны все поды с помощью unseal key
 - Создано хранилище секретов otus/ с Secret Engine KV-v1
 - Создан секрет otus/cred с username='otus' и password='asajkjkahs'
 - Создан ServiceAccount vault-auth и ClusterRoleBinding с ролью system:auth-delegator
 - Настроена авторизация auth/kubernetes в Vault с использованием токена и сертификата ServiceAccount
 - Создана политика otus-policy для секретов /otus/cred с capabilities = ["read", "list"]
 - Создана роль auth/kubernetes/role/otus с использованием ServiceAccount vault-auth и политики otus-policy
 - Установлен External Secrets Operator из helm-чарта в namespace vault
 - Создан и применен манифест SecretStore, сконфигурированный для доступа к KV секретам Vault
 - Создан и применен манифест ExternalSecret для синхронизации секрета otus/cred в Kubernetes Secret otus-cred

## Как запустить проект:

### 1. Установка Consul:
```bash
cd /tmp && git clone https://github.com/hashicorp/consul-helm.git --depth 1
cd /tmp/consul-helm && helm template consul . \
  --namespace consul \
  --set global.name=consul \
  --set global.datacenter=dc1 \
  --set server.replicas=3 \
  --set server.bootstrapExpect=3 \
  --set server.storage=10Gi \
  --set connectInject.enabled=false \
  --set controller.enabled=false \
  --set meshGateway.enabled=false \
  --set ingressGateways.enabled=false \
  --set terminatingGateways.enabled=false \
  | sed 's/policy\/v1beta1/policy\/v1/g' | kubectl apply -f -
```

### 2. Установка Vault:
```bash
cd /tmp && git clone https://github.com/hashicorp/vault-helm.git --depth 1
cd /tmp/vault-helm && helm template vault . \
  --namespace vault \
  -f /path/to/kubernetes-vault/vault-values-ha.yaml \
  | sed 's/policy\/v1beta1/policy\/v1/g' | kubectl apply -f -
```

### 3. Инициализация Vault:
```bash
# Инициализация
kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > /tmp/vault-init.json

# Распечатывание всех подов
UNSEAL_KEY=$(cat /tmp/vault-init.json | jq -r '.unseal_keys_b64[0]')
for i in 0 1 2; do kubectl exec -n vault vault-$i -- vault operator unseal $UNSEAL_KEY; done
```

### 4. Создание секретов в Vault:
```bash
ROOT_TOKEN=$(cat /tmp/vault-init.json | jq -r '.root_token')
kubectl exec -n vault vault-0 -- sh -c "export VAULT_ADDR=http://127.0.0.1:8200 && export VAULT_TOKEN=$ROOT_TOKEN && vault secrets enable -path=otus kv-v1"
kubectl exec -n vault vault-0 -- sh -c "export VAULT_ADDR=http://127.0.0.1:8200 && export VAULT_TOKEN=$ROOT_TOKEN && vault kv put otus/cred username=otus password=asajkjkahs"
```

### 5. Настройка авторизации Kubernetes:
```bash
# Создание ServiceAccount и ClusterRoleBinding
kubectl apply -f kubernetes-vault/vault-auth-sa.yaml

# Настройка Kubernetes auth в Vault
CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d)
SA_TOKEN=$(kubectl create token vault-auth -n vault --duration=8760h)
KUBE_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')
ROOT_TOKEN=$(cat /tmp/vault-init.json | jq -r '.root_token')

kubectl exec -n vault vault-0 -- sh -c "export VAULT_ADDR=http://127.0.0.1:8200 && export VAULT_TOKEN=$ROOT_TOKEN && vault auth enable kubernetes"

kubectl exec -n vault vault-0 -- sh -c "export VAULT_ADDR=http://127.0.0.1:8200 && export VAULT_TOKEN=$ROOT_TOKEN && vault write auth/kubernetes/config token='$SA_TOKEN' kubernetes_host='$KUBE_HOST' kubernetes_ca_cert='$CA_CERT'"
```

### 6. Создание политики и роли:
```bash
# Создание политики
kubectl cp kubernetes-vault/vault-policy.hcl vault/vault-0:/tmp/otus-policy.hcl
ROOT_TOKEN=$(cat /tmp/vault-init.json | jq -r '.root_token')
kubectl exec -n vault vault-0 -- sh -c "export VAULT_ADDR=http://127.0.0.1:8200 && export VAULT_TOKEN=$ROOT_TOKEN && vault policy write otus-policy /tmp/otus-policy.hcl"

# Создание роли
kubectl exec -n vault vault-0 -- sh -c "export VAULT_ADDR=http://127.0.0.1:8200 && export VAULT_TOKEN=$ROOT_TOKEN && vault write auth/kubernetes/role/otus bound_service_account_names=vault-auth bound_service_account_namespaces=vault policies=otus-policy ttl=1h"
```

### 7. Установка External Secrets Operator:
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm install external-secrets external-secrets/external-secrets --namespace vault --create-namespace
```

### 8. Создание SecretStore и ExternalSecret:
```bash
kubectl apply -f kubernetes-vault/secretstore.yaml
kubectl apply -f kubernetes-vault/externalsecret.yaml
```

## Как проверить работоспособность:

### Проверка статуса подов:
```bash
# Проверка Consul
kubectl get pods -n consul
# Должно быть 3 сервера и несколько клиентов в статусе Running

# Проверка Vault
kubectl get pods -n vault
# Должно быть 3 реплики vault в статусе Running

# Проверка External Secrets Operator
kubectl get pods -n vault | grep external-secrets
```

### Проверка SecretStore:
```bash
kubectl get secretstore -n vault
kubectl describe secretstore vault-secretstore -n vault
# Статус должен быть Valid и Ready = True
```

### Проверка ExternalSecret:
```bash
kubectl get externalsecret -n vault
kubectl describe externalsecret otus-cred -n vault
# Статус должен быть SecretSynced и Ready = True
```

### Проверка созданного Secret:
```bash
kubectl get secret otus-cred -n vault
kubectl get secret otus-cred -n vault -o jsonpath='{.data.username}' | base64 -d
kubectl get secret otus-cred -n vault -o jsonpath='{.data.password}' | base64 -d
# Должны быть значения: username=otus, password=asajkjkahs
```

### Проверка секрета в Vault:
```bash
ROOT_TOKEN=$(cat /tmp/vault-init.json | jq -r '.root_token')
kubectl exec -n vault vault-0 -- sh -c "export VAULT_ADDR=http://127.0.0.1:8200 && export VAULT_TOKEN=$ROOT_TOKEN && vault kv get otus/cred"
```

## PR checklist:
 - [ ] Выставлен label с темой домашнего задания

## Структура файлов в репозитории:

- `consul-install-command.txt` - команда установки Consul
- `consul-values.yaml` - значения для установки Consul
- `vault-install-command.txt` - команда установки Vault
- `vault-values-ha.yaml` - значения для установки Vault в HA режиме
- `vault-auth-sa.yaml` - ServiceAccount и ClusterRoleBinding для авторизации
- `vault-policy.hcl` - политика доступа к секретам
- `secretstore.yaml` - манифест SecretStore для External Secrets Operator
- `externalsecret.yaml` - манифест ExternalSecret для синхронизации секрета
- `external-secrets-install-command.txt` - команда установки External Secrets Operator
- `README.md` - описание проекта
