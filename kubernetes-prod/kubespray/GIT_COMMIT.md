# Коммит файлов для задания со звездочкой

## Файлы для коммита

### Обязательные файлы для сдачи (должны быть созданы на ВМ):

1. **`kubespray/inventory.ini`** - inventory файл с реальными IP
   - Создать на ВМ: `cp /tmp/kubespray/inventory/ha-cluster/hosts.yaml kubespray/inventory.ini`

2. **`outputs/kubespray-nodes.txt`** - вывод `kubectl get nodes -o wide`
   - Создать на ВМ: `kubectl get nodes -o wide > outputs/kubespray-nodes.txt`

### Файлы для коммита (документация и шаблоны):

- `kubespray/README.md` - основная инструкция
- `kubespray/hosts.yaml` - готовый hosts.yaml с реальными IP
- `kubespray/ansible.cfg` - конфигурация Ansible
- `kubespray/inventory.ini.template` - шаблон inventory файла
- `kubespray/vms-ha-info.txt` - информация о ВМ
- `kubespray/*.md` - дополнительная документация
- `kubespray/setup-kubectl.sh` - скрипт настройки kubectl

## Команды для коммита

### Вариант 1: Коммит всех файлов kubespray (кроме служебных)

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

# Проверка что будет добавлено
git status

# Коммит
git commit -m "Add kubespray files for HA cluster deployment

- Add README.md with deployment instructions
- Add hosts.yaml with real IP addresses
- Add ansible.cfg for Ansible configuration
- Add inventory.ini.template as template
- Add vms-ha-info.txt with VM information
- Add supporting documentation files"

# Отправка в репозиторий
git push origin kubernetes-prod
```

### Вариант 2: Коммит только обязательных файлов

```bash
cd /home/konstsima/SimonKonstantinov_repo

# После сохранения inventory.ini и kubespray-nodes.txt на ВМ:
git add kubernetes-prod/kubespray/inventory.ini
git add kubernetes-prod/outputs/kubespray-nodes.txt
git add kubernetes-prod/kubespray/README.md
git add kubernetes-prod/kubespray/hosts.yaml

git commit -m "Add kubespray HA cluster deployment results

- Add inventory.ini with real IP addresses
- Add kubespray-nodes.txt with cluster status
- Add README.md with deployment instructions"

git push origin kubernetes-prod
```

## Важно

Перед коммитом убедитесь, что:
1. ✅ `kubespray/inventory.ini` создан (скопирован с ВМ)
2. ✅ `outputs/kubespray-nodes.txt` создан (сохранен с ВМ)

Эти файлы создаются на ВМ k8s-learning-vm после развертывания кластера!
