# Команды для подключения к ВМ

## Master-нода

```bash
# С использованием ключа (рекомендуется)
ssh -i ~/.ssh/k8s_cluster_key -l ubuntu 89.169.176.122

# Или в современном формате
ssh -i ~/.ssh/k8s_cluster_key ubuntu@89.169.176.122
```

## Worker-ноды

```bash
# Worker-1
ssh -i ~/.ssh/k8s_cluster_key -l ubuntu 178.154.197.48

# Worker-2
ssh -i ~/.ssh/k8s_cluster_key -l ubuntu 178.154.194.129

# Worker-3
ssh -i ~/.ssh/k8s_cluster_key -l ubuntu 178.154.196.219
```

## Настройка SSH config для удобства

Добавьте в `~/.ssh/config`:

```bash
cat >> ~/.ssh/config << 'EOF'
Host k8s-master
    HostName 89.169.176.122
    User ubuntu
    IdentityFile ~/.ssh/k8s_cluster_key
    StrictHostKeyChecking no

Host k8s-worker-1
    HostName 178.154.197.48
    User ubuntu
    IdentityFile ~/.ssh/k8s_cluster_key
    StrictHostKeyChecking no

Host k8s-worker-2
    HostName 178.154.194.129
    User ubuntu
    IdentityFile ~/.ssh/k8s_cluster_key
    StrictHostKeyChecking no

Host k8s-worker-3
    HostName 178.154.196.219
    User ubuntu
    IdentityFile ~/.ssh/k8s_cluster_key
    StrictHostKeyChecking no
EOF
```

После этого можно подключаться просто:
```bash
ssh k8s-master
ssh k8s-worker-1
ssh k8s-worker-2
ssh k8s-worker-3
```

## Проверка подключения

После подключения проверьте:
```bash
hostname
whoami
free -h
nproc
```

## Следующие шаги

После успешного подключения к master-ноде выполните команды из:
- `commands/QUICK_MASTER_SETUP.md` - быстрая настройка
- `commands/MASTER_COMMANDS.sh` - полный скрипт
- `commands/01-prepare-master.md` - пошаговые инструкции
