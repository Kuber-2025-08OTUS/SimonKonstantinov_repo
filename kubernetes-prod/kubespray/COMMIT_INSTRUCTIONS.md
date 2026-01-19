# Инструкция по коммиту файлов для задания со звездочкой

## Важно перед коммитом

**Обязательные файлы должны быть сохранены с ВМ k8s-learning-vm:**

1. `kubespray/inventory.ini` - скопировать с ВМ:
   ```bash
   # На ВМ k8s-learning-vm:
   cp /tmp/kubespray/inventory/ha-cluster/hosts.yaml \
      /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/kubespray/inventory.ini
   ```

2. `outputs/kubespray-nodes.txt` - сохранить вывод kubectl:
   ```bash
   # На ВМ k8s-learning-vm:
   mkdir -p /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs
   kubectl get nodes -o wide > /home/konstsima/SimonKonstantinov_repo/kubernetes-prod/outputs/kubespray-nodes.txt
   ```

## Команды для коммита

### Шаг 1: Добавление файлов kubespray

```bash
cd /home/konstsima/SimonKonstantinov_repo

# Добавить все файлы kubespray
git add kubernetes-prod/kubespray/

# Или добавить конкретные файлы
git add kubernetes-prod/kubespray/README.md
git add kubernetes-prod/kubespray/hosts.yaml
git add kubernetes-prod/kubespray/ansible.cfg
git add kubernetes-prod/kubespray/inventory.ini.template
git add kubernetes-prod/kubespray/vms-ha-info.txt
git add kubernetes-prod/kubespray/*.md
git add kubernetes-prod/kubespray/*.sh

# После сохранения обязательных файлов:
git add kubernetes-prod/kubespray/inventory.ini
git add kubernetes-prod/outputs/kubespray-nodes.txt
```

### Шаг 2: Проверка что будет добавлено

```bash
git status
```

### Шаг 3: Коммит

```bash
git commit -m "Add kubespray HA cluster deployment files

- Add README.md with deployment instructions
- Add hosts.yaml with real VM IP addresses
- Add ansible.cfg for Ansible configuration
- Add inventory.ini.template as template
- Add vms-ha-info.txt with VM information
- Add supporting documentation files
- Add setup-kubectl.sh script"
```

### Шаг 4: Отправка в репозиторий

```bash
git push origin kubernetes-prod
```

## После сохранения обязательных файлов

После того, как вы сохраните `inventory.ini` и `kubespray-nodes.txt` с ВМ, добавьте их:

```bash
cd /home/konstsima/SimonKonstantinov_repo

git add kubernetes-prod/kubespray/inventory.ini
git add kubernetes-prod/outputs/kubespray-nodes.txt

git commit -m "Add kubespray HA cluster deployment results

- Add inventory.ini with real IP addresses used for deployment
- Add kubespray-nodes.txt with cluster status (5 nodes Ready)"

git push origin kubernetes-prod
```

## Итоговый список файлов для сдачи

После коммита у вас должны быть в репозитории:

1. ✅ `kubespray/inventory.ini` - inventory файл с реальными IP-адресами
2. ✅ `outputs/kubespray-nodes.txt` - вывод `kubectl get nodes -o wide` с 5 нодами в статусе Ready
