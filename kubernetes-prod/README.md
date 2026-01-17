# Kubernetes Production Deployment

Домашнее задание по развертыванию и обновлению production-grade кластера Kubernetes.

## Цели задания

1. Создать кластер с использованием kubeadm
2. Понимать как обновить кластер до нужной версии kubernetes с использованием kubeadm
3. Создать кластер с использованием kubespray (задание с *)

## Требования к инфраструктуре

### Основное задание
- **Master node**: 1 узел, 2vCPU, 8GB RAM
- **Worker nodes**: 3 узла, 2vCPU, 8GB RAM
- **Версия Kubernetes**: 1.34.x (на одну ниже актуальной 1.35.x)

### Задание с * (опционально)
- **Master nodes**: 3 узла, 2vCPU, 8GB RAM (HA)
- **Worker nodes**: минимум 2 узла, 2vCPU, 8GB RAM

## Структура проекта

```
kubernetes-prod/
├── README.md                    # Этот файл
├── QUICK_START.md              # Краткая инструкция по быстрому старту
├── PR_DESCRIPTION.md           # Шаблон описания для Pull Request
├── commands/                    # Пошаговые команды для выполнения
│   ├── README.md               # Описание структуры команд
│   ├── 01-prepare-master.md    # Команды для подготовки master-ноды
│   ├── 02-prepare-worker.md    # Команды для подготовки worker-нод
│   ├── 03-init-cluster.md      # Команды для инициализации кластера
│   └── 04-upgrade-cluster.md   # Команды для обновления кластера
├── outputs/                     # Результаты выполнения
│   ├── nodes-before-upgrade.txt # kubectl get nodes до обновления
│   └── nodes-after-upgrade.txt # kubectl get nodes после обновления
└── kubespray/                   # Файлы для kubespray (если выполняется задание с *)
    ├── README.md
    └── inventory.ini.template   # Шаблон inventory файла для kubespray
```

## Выполнение задания

### Этап 1: Подготовка узлов

1. Отключить swap на всех узлах
2. Включить маршрутизацию
3. Настроить необходимые параметры ядра

**Примечание:** Все команды для этого этапа описаны в `commands/01-prepare-master.md` и `commands/02-prepare-worker.md`

### Этап 2: Установка компонентов

1. Установить containerd на все ВМ
2. Установить kubeadm, kubelet, kubectl на все ВМ

**Примечание:** 
- Версия Kubernetes должна быть на одну ниже актуальной
- В файлах команд указана версия 1.29.x как пример, при необходимости обновите на актуальную версию
- Все команды описаны в `commands/01-prepare-master.md` и `commands/02-prepare-worker.md`

### Этап 3: Инициализация кластера

1. На master-ноде выполнить:
   ```bash
   kubeadm init --pod-network-cidr=10.244.0.0/16
   ```
   Сохранить команду `kubeadm join` из вывода

2. Настроить kubectl на master-ноде:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

3. Установить Flannel в качестве сетевого плагина:
   ```bash
   kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
   ```

4. На каждой worker-ноде выполнить сохраненную команду `kubeadm join`

5. Проверить статус кластера:
   ```bash
   kubectl get nodes -o wide
   ```
   Сохранить вывод в `outputs/nodes-before-upgrade.txt`

### Этап 4: Обновление кластера

1. Обновить master-ноду до последней актуальной версии k8s:
   - Обновить kubeadm
   - Выполнить `kubeadm upgrade plan`
   - Выполнить `kubeadm upgrade apply v<версия>`
   - Обновить kubelet и kubectl
   - Перезапустить kubelet

2. Для каждой worker-ноды последовательно:
   - На master-ноде: `kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data`
   - На worker-ноде: обновить kubeadm, kubelet, kubectl
   - На worker-ноде: выполнить `kubeadm upgrade node`
   - На worker-ноде: перезапустить kubelet
   - На master-ноде: `kubectl uncordon <node-name>`

3. Проверить статус кластера после обновления:
   ```bash
   kubectl get nodes -o wide
   ```
   Сохранить вывод в `outputs/nodes-after-upgrade.txt`

**Примечание:** Подробные команды см. в `commands/04-upgrade-cluster.md`

## Результаты

После выполнения задания должны быть предоставлены:

- [ ] Вывод `kubectl get nodes -o wide` до обновления (сохранить в `outputs/nodes-before-upgrade.txt`)
- [ ] Вывод `kubectl get nodes -o wide` после обновления (сохранить в `outputs/nodes-after-upgrade.txt`)
- [ ] Все команды, выполненные на master-ноде (документированы в `commands/01-prepare-master.md` и `commands/03-init-cluster.md`)
- [ ] Все команды, выполненные на worker-нодах (документированы в `commands/02-prepare-worker.md`)
- [ ] Все команды по обновлению версии кластера (документированы в `commands/04-upgrade-cluster.md`)

### Задание со * (kubespray)

Для выполнения задания со звездочкой (HA-кластер с kubespray):

- [ ] Создано минимум 5 ВМ: 3 master (2vCPU, 8GB RAM) + 2 worker (2vCPU, 8GB RAM)
- [ ] Развернут HA-кластер Kubernetes с помощью kubespray
- [ ] Приложен inventory файл (`kubespray/inventory.ini`) с реальными IP-адресами
- [ ] Приложен вывод команды `kubectl get nodes -o wide` (`outputs/kubespray-nodes.txt`)

**Подробная инструкция:** см. `kubespray/DEPLOY_HA_CLUSTER.md`

## Полезные ссылки

- [Создание кластера с помощью kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Обновление версии кластера с использованием kubeadm](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Создание кластера с использованием kubespray](https://kubespray.io/)
