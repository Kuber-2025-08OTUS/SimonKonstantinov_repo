# Команды для обновления кластера с версии 1.34 до 1.35

**Официальная документация:** [Upgrading kubeadm clusters](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-upgrade/)

**Текущее состояние кластера:**
- **Текущая версия:** v1.34.3 (все ноды)
- **Целевая версия:** v1.35.0
- **Master нода:** k8s-master (10.129.0.10) - v1.34.3
- **Worker ноды:** k8s-worker-1 (10.129.0.22), k8s-worker-2 (10.129.0.18), k8s-worker-3 (10.129.0.31) - v1.34.3

---

## Критически важный шаг: Удаление флага --pod-infra-container-image

**ВНИМАНИЕ:** Перед началом обновления необходимо удалить устаревший флаг `--pod-infra-container-image` на **всех узлах кластера** (master и все worker-ноды). Этот флаг устарел и может вызвать проблемы при обновлении до версии 1.35.

### На worker-нодах (k8s-worker-1, k8s-worker-2, k8s-worker-3)

Для каждой worker-ноды выполните следующие шаги **последовательно** (по одной ноде за раз):

#### Шаг 1: Вывод ноды из эксплуатации (на master-ноде)

```bash
# Подключитесь к master-ноде
ssh -i k8s-key master@178.154.197.32

# Выведите ноду из эксплуатации (выполните на master-ноде)
kubectl drain k8s-worker-1 --ignore-daemonsets --delete-emptydir-data

# Проверка: нода должна быть в статусе SchedulingDisabled
kubectl get nodes
```

#### Шаг 2: Удаление флага на worker-ноде

На worker-ноде выполните:

```bash
# Подключитесь к worker-ноде (например, k8s-worker-1)
ssh -i k8s-key node1@158.160.67.215

# 1. Остановите kubelet
sudo systemctl stop kubelet

# 2. Удалите флаг --pod-infra-container-image из конфигурации
sudo sed -i '/pod-infra-container-image/d' /var/lib/kubelet/kubeadm-flags.env

# 3. ВАЖНО: Убедитесь, что файл содержит правильный префикс KUBELET_KUBEADM_ARGS=
# Если файл пустой или не содержит префикс, восстановите его:
if [ ! -s /var/lib/kubelet/kubeadm-flags.env ] || ! grep -q "^KUBELET_KUBEADM_ARGS=" /var/lib/kubelet/kubeadm-flags.env; then
  echo "Восстановление файла kubeadm-flags.env..."
  echo 'KUBELET_KUBEADM_ARGS=""' | sudo tee /var/lib/kubelet/kubeadm-flags.env > /dev/null
fi

# 4. Проверьте содержимое файла (должен содержать KUBELET_KUBEADM_ARGS= без pod-infra-container-image)
sudo cat /var/lib/kubelet/kubeadm-flags.env
# Должен показать что-то вроде: KUBELET_KUBEADM_ARGS="" или KUBELET_KUBEADM_ARGS="--flag1 --flag2" (без pod-infra-container-image)

# 4. Запустите kubelet
sudo systemctl start kubelet

# 5. Проверьте статус kubelet
sudo systemctl status kubelet
```

#### Шаг 3: Возврат ноды в строй (на master-ноде)

```bash
# Вернитесь на master-ноду
ssh -i k8s-key master@178.154.197.32

# Верните ноду в строй (выполните на master-ноде)
kubectl uncordon k8s-worker-1

# Проверка: нода должна вернуться в статус Ready
kubectl get nodes
```

**Повторите шаги 1-3 для остальных worker-нод:**
- k8s-worker-2 (158.160.78.216, пользователь: node2)
- k8s-worker-3 (158.160.77.191, пользователь: node3)

### На master-ноде (k8s-master)

На master-ноде выполните без drain/uncordon (но с остановкой kubelet):

```bash
# Подключитесь к master-ноде
ssh -i k8s-key master@178.154.197.32

# 1. Остановите kubelet
sudo systemctl stop kubelet

# 2. Удалите флаг --pod-infra-container-image из конфигурации
sudo sed -i '/pod-infra-container-image/d' /var/lib/kubelet/kubeadm-flags.env

# 3. ВАЖНО: Убедитесь, что файл содержит правильный префикс KUBELET_KUBEADM_ARGS=
# Если файл пустой или не содержит префикс, восстановите его:
if [ ! -s /var/lib/kubelet/kubeadm-flags.env ] || ! grep -q "^KUBELET_KUBEADM_ARGS=" /var/lib/kubelet/kubeadm-flags.env; then
  echo "Восстановление файла kubeadm-flags.env..."
  echo 'KUBELET_KUBEADM_ARGS=""' | sudo tee /var/lib/kubelet/kubeadm-flags.env > /dev/null
fi

# 4. Проверьте содержимое файла (должен содержать KUBELET_KUBEADM_ARGS= без pod-infra-container-image)
sudo cat /var/lib/kubelet/kubeadm-flags.env
# Должен показать что-то вроде: KUBELET_KUBEADM_ARGS="" или KUBELET_KUBEADM_ARGS="--flag1 --flag2" (без pod-infra-container-image)

# 4. Запустите kubelet
sudo systemctl start kubelet

# 5. Проверьте статус kubelet
sudo systemctl status kubelet

# 6. Проверьте, что master-нода в статусе Ready
kubectl get nodes
```

### Проверка перед обновлением

После удаления флага на всех узлах, убедитесь что:

```bash
# Все ноды в состоянии Ready (на master-ноде)
kubectl get nodes -o wide
# Должны быть все 4 ноды: k8s-master, k8s-worker-1, k8s-worker-2, k8s-worker-3 в статусе Ready

# kubelet работает на всех нодах (проверьте на каждой ноде)
sudo systemctl status kubelet

# Проверка версии cgroups (выполните на каждой ноде)
stat -fc %T /sys/fs/cgroup/
# Должно показать:
# - cgroup2fs для cgroups v2 (рекомендуется)
# - tmpfs для cgroups v1 (может потребоваться дополнительная настройка)
```

**ВАЖНО о cgroups:**
- Если у вас cgroups v2 (cgroup2fs), обновление должно пройти без проблем
- Если у вас cgroups v1 (tmpfs), может потребоваться дополнительная настройка

**После выполнения этих шагов на всех узлах можно приступать к обновлению кластера.**

---

## Порядок обновления кластера с версии 1.34 до 1.35

**Согласно официальной документации Kubernetes:** [Upgrading kubeadm clusters](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-upgrade/)

**Порядок обновления:**
1. ✅ **Подготовка:** Удалить флаг `--pod-infra-container-image` на всех узлах (выполнено выше)
2. **Обновление master-ноды:** Обновить master до версии 1.35
3. **Обновление worker-нод:** Обновить каждую worker-ноду последовательно (по одной)

**ВАЖНО:** 
- Обновляйте узлы последовательно (не параллельно)
- Убедитесь, что master-нода полностью обновлена и работает перед обновлением worker-нод
- Для каждой worker-ноды используйте `kubectl drain` перед обновлением и `kubectl uncordon` после обновления

---

## Обновление master-ноды

Все команды выполняются на master-ноде (k8s-master, 10.129.0.10).

### 1. Обновление kubeadm до версии 1.35

**Выполните на master-ноде:**

```bash
# Подключитесь к master-ноде
ssh -i k8s-key master@178.154.197.32

# Снятие фиксации версии
sudo apt-mark unhold kubeadm

# Обновление списка пакетов
sudo apt-get update

# Проверка текущей версии kubeadm (для информации)
kubeadm version

# Добавление репозитория Kubernetes для версии 1.35
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Обновление списка пакетов
sudo apt-get update

# ВАЖНО: Сначала проверьте доступные версии kubeadm
echo "Проверка доступных версий kubeadm 1.35..."
apt-cache madison kubeadm | grep 1.35

# Если версии найдены, посмотрите точную версию пакета
# Пример вывода: kubeadm | 1.35.0-1.1 | https://pkgs.k8s.io/core:/stable:/v1.35/deb  amd64 Packages
# Скопируйте точную версию из вывода (например, 1.35.0-1.1)

# Если версии не найдены через madison, проверьте через policy:
if ! apt-cache madison kubeadm | grep -q 1.35; then
  echo "Версии 1.35 не найдены через madison. Проверяю через policy..."
  apt-cache policy kubeadm
  echo "Проверьте доступные версии выше и используйте точную версию"
fi

# Установка новой версии kubeadm 1.35
# МЕТОД 1: Если вы видите версию в выводе выше, используйте её точно:
# sudo apt-get install -y kubeadm=1.35.0-1.1
# (замените 1.35.0-1.1 на реальную версию из вывода apt-cache madison)

# МЕТОД 2: Попробовать паттерн (может не работать, если версия не найдена):
VERSION=$(apt-cache madison kubeadm | grep 1.35 | head -1 | awk '{print $3}')
if [ -n "$VERSION" ]; then
  echo "Установка версии: $VERSION"
  sudo apt-get install -y kubeadm=$VERSION
else
  echo "ВНИМАНИЕ: Версия 1.35 не найдена в репозитории!"
  echo "Проверьте доступные версии командой: apt-cache madison kubeadm"
  echo "Или проверьте правильность репозитория: cat /etc/apt/sources.list.d/kubernetes.list"
  exit 1
fi

# Фиксация версии
sudo apt-mark hold kubeadm

# Проверка версии (должна быть v1.35.0 или выше)
kubeadm version
```

**ВАЖНО о версиях пакетов:** 
- ❌ **НЕ используйте** `kubeadm=1.35.0` без ревизии - эта команда не найдет пакет!
- ✅ **ИСПОЛЬЗУЙТЕ** сначала команду `apt-cache madison kubeadm | grep 1.35` для проверки доступных версий
- ✅ **ИСПОЛЬЗУЙТЕ** точную версию из вывода (например, `kubeadm=1.35.0-1.1` вместо `kubeadm=1.35.0-*`)
- ✅ **АЛЬТЕРНАТИВА:** Используйте автоматическое определение версии через скрипт в инструкциях ниже
- ⚠️ Если версия 1.35 еще не доступна в репозитории, возможно нужно:
  - Подождать релиза пакетов
  - Проверить правильность настройки репозитория
  - Использовать последнюю доступную версию из репозитория

### 2. Просмотр плана обновления

**Выполните на master-ноде:**

```bash
# Просмотр плана обновления
sudo kubeadm upgrade plan

# Команда покажет:
# - Текущую версию кластера (v1.34.3)
# - Доступные версии для обновления (v1.35.0)
# - Компоненты, которые будут обновлены
# - Рекомендации по обновлению
```

**ВАЖНО:** 
- Проверьте вывод команды. Она должна показать, что можно обновить с v1.34.3 до v1.35.0
- Если версия 1.35.0 не доступна, проверьте доступные версии командой:
  ```bash
  apt-cache madison kubeadm | grep 1.35
  ```
- Используйте доступную версию, например `1.35.0-1.1` или другую доступную версию из списка

### 3. Применение обновления master-ноды

**Выполните на master-ноде:**

```bash
# ВАЖНО: Перед применением обновления убедитесь, что версия 1.35 доступна
# Проверьте доступные версии в выводе kubeadm upgrade plan

# Применение обновления до версии 1.35.0
# Если версия 1.35.0 недоступна, используйте последнюю доступную версию 1.35.x
sudo kubeadm upgrade apply v1.35.0 --yes || \
  (echo "Версия v1.35.0 может быть недоступна. Проверьте доступные версии:" && \
   sudo kubeadm upgrade plan)

# Команда выполнит:
# - Обновление статических манифестов подов (kube-apiserver, kube-controller-manager, kube-scheduler, etcd)
# - Обновление конфигурации кластера
# - Обновление сертификатов (если нужно)

# После успешного выполнения команды вы увидите сообщение:
# "[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.35.0". Enjoy!"
```

**ВАЖНО:** 
- Обновление может занять несколько минут
- Не прерывайте процесс обновления
- После обновления kubelet автоматически перезапустится

**❗ Если возникла ошибка с файлом kubeadm-flags.env:**

Если при выполнении `kubeadm upgrade apply` вы получили ошибку:
```
error: error execution phase post-upgrade: error reading kubelet env file: the file "/var/lib/kubelet/kubeadm-flags.env" does not contain the expected prefix "KUBELET_KUBEADM_ARGS="
```

Это означает, что файл `/var/lib/kubelet/kubeadm-flags.env` поврежден или пустой. Исправьте его:

```bash
# Проверьте текущее содержимое файла
cat /var/lib/kubelet/kubeadm-flags.env

# Если файл пустой или не содержит префикс KUBELET_KUBEADM_ARGS=, восстановите его:
echo 'KUBELET_KUBEADM_ARGS=""' | sudo tee /var/lib/kubelet/kubeadm-flags.env > /dev/null

# Или если в файле есть другие флаги (без pod-infra-container-image), добавьте префикс:
# Если файл содержит только флаги, например: "--network-plugin=cni --cni-conf-dir=/etc/cni/net.d"
# Добавьте префикс:
# echo 'KUBELET_KUBEADM_ARGS="--network-plugin=cni --cni-conf-dir=/etc/cni/net.d"' | sudo tee /var/lib/kubelet/kubeadm-flags.env > /dev/null

# Проверьте содержимое
cat /var/lib/kubelet/kubeadm-flags.env
# Должно показать: KUBELET_KUBEADM_ARGS="..."

# После исправления файла, НЕ нужно повторять kubeadm upgrade apply
# Контрольная плоскость уже обновлена (etcd, kube-apiserver, kube-controller-manager, kube-scheduler)
# Просто завершите обновление, выполнив оставшиеся шаги (обновление kubelet и kubectl) из шага 4 ниже

# После исправления файла kubeadm-flags.env, перезапустите kubelet:
sudo systemctl restart kubelet

# Проверьте статус kubelet
sudo systemctl status kubelet

# Затем продолжайте с шага 4 (Обновление kubelet и kubectl на master-ноде)
```

### 4. Обновление kubelet и kubectl на master-ноде

**Выполните на master-ноде:**

```bash
# Снятие фиксации версий
sudo apt-mark unhold kubelet kubectl

# Обновление списка пакетов
sudo apt-get update

# ВАЖНО: Проверьте доступные версии перед установкой
echo "Проверка доступных версий kubelet и kubectl 1.35..."
apt-cache madison kubelet | grep 1.35
apt-cache madison kubectl | grep 1.35

# Получение точных версий из вывода
KUBELET_VERSION=$(apt-cache madison kubelet | grep 1.35 | head -1 | awk '{print $3}')
KUBECTL_VERSION=$(apt-cache madison kubectl | grep 1.35 | head -1 | awk '{print $3}')

# Установка новых версий kubelet и kubectl 1.35
if [ -n "$KUBELET_VERSION" ] && [ -n "$KUBECTL_VERSION" ]; then
  echo "Установка kubelet версии: $KUBELET_VERSION"
  echo "Установка kubectl версии: $KUBECTL_VERSION"
  sudo apt-get install -y kubelet=$KUBELET_VERSION kubectl=$KUBECTL_VERSION
else
  echo "ВНИМАНИЕ: Версии 1.35 не найдены для kubelet или kubectl!"
  echo "Проверьте доступные версии:"
  apt-cache madison kubelet | grep 1.35 || echo "kubelet 1.35 не найден"
  apt-cache madison kubectl | grep 1.35 || echo "kubectl 1.35 не найден"
  echo "Используйте точные версии из вывода выше для установки"
  exit 1
fi

# Фиксация версий (предотвращение автоматического обновления)
sudo apt-mark hold kubelet kubectl

# Перезагрузка конфигурации systemd
sudo systemctl daemon-reload

# Перезапуск kubelet
sudo systemctl restart kubelet

# Проверка статуса kubelet
sudo systemctl status kubelet
```

### 5. Проверка обновления master-ноды

**Выполните на master-ноде:**

```bash
# Проверка статуса нод
kubectl get nodes -o wide

# Должен показать master-ноду с версией v1.35.0
# Пример вывода:
# NAME         STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
# k8s-master   Ready    control-plane   Xh    v1.35.0   10.129.0.10   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
# k8s-worker-1 Ready    <none>          Xh    v1.34.3   10.129.0.22   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
# k8s-worker-2 Ready    <none>          Xh    v1.34.3   10.129.0.18   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
# k8s-worker-3 Ready    <none>          Xh    v1.34.3   10.129.0.31   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1

# Проверка версии kubectl
kubectl version --short

# Проверка системных подов
kubectl get pods -n kube-system

# Все поды должны быть в статусе Running
```

**ВАЖНО:** После обновления master-ноды до версии 1.35, все worker-ноды еще будут в версии 1.34.3. Это нормально - worker-ноды обновляются отдельно.

---

## Обновление worker-нод

Для каждой worker-ноды выполните следующие шаги **последовательно** (по одной ноде за раз):

**Список worker-нод для обновления:**
- k8s-worker-1 (158.160.67.215) - пользователь: node1
- k8s-worker-2 (158.160.78.216) - пользователь: node2
- k8s-worker-3 (158.160.77.191) - пользователь: node3

### Шаг 1: Вывод ноды из планирования (на master-ноде)

**Выполните на master-ноде:**

```bash
# Подключитесь к master-ноде
ssh -i k8s-key master@178.154.197.32

# Выведите ноду из эксплуатации (замените k8s-worker-1 на нужную ноду)
kubectl drain k8s-worker-1 --ignore-daemonsets --delete-emptydir-data

# Проверка:
kubectl get nodes
# Нода должна быть в статусе SchedulingDisabled
```

### Шаг 2: Обновление компонентов на worker-ноде

**Выполните на worker-ноде (например, k8s-worker-1):**

```bash
# Подключитесь к worker-ноде
ssh -i k8s-key node1@158.160.67.215

# 1. Обновление kubeadm до версии 1.35
sudo apt-mark unhold kubeadm
sudo apt-get update

# Добавление репозитория Kubernetes для версии 1.35 (если еще не добавлен)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# ВАЖНО: Проверьте доступные версии kubeadm перед установкой
echo "Проверка доступных версий kubeadm 1.35..."
apt-cache madison kubeadm | grep 1.35

# Получение точной версии из вывода
KUBEADM_VERSION=$(apt-cache madison kubeadm | grep 1.35 | head -1 | awk '{print $3}')

# Установка новой версии kubeadm 1.35
if [ -n "$KUBEADM_VERSION" ]; then
  echo "Установка kubeadm версии: $KUBEADM_VERSION"
  sudo apt-get install -y kubeadm=$KUBEADM_VERSION
else
  echo "ВНИМАНИЕ: Версия 1.35 не найдена для kubeadm!"
  echo "Проверьте доступные версии:"
  apt-cache madison kubeadm | grep 1.35 || echo "kubeadm 1.35 не найден"
  echo "Используйте точную версию из вывода выше для установки"
  exit 1
fi

sudo apt-mark hold kubeadm

# 2. Обновление конфигурации ноды (важно: использует новый kubeadm)
sudo kubeadm upgrade node

# 3. Обновление kubelet и kubectl до версии 1.35
sudo apt-mark unhold kubelet kubectl
sudo apt-get update

# ВАЖНО: Проверьте доступные версии перед установкой
echo "Проверка доступных версий kubelet и kubectl 1.35..."
apt-cache madison kubelet | grep 1.35
apt-cache madison kubectl | grep 1.35

# Получение точных версий из вывода
KUBELET_VERSION=$(apt-cache madison kubelet | grep 1.35 | head -1 | awk '{print $3}')
KUBECTL_VERSION=$(apt-cache madison kubectl | grep 1.35 | head -1 | awk '{print $3}')

# Установка новых версий kubelet и kubectl 1.35
if [ -n "$KUBELET_VERSION" ] && [ -n "$KUBECTL_VERSION" ]; then
  echo "Установка kubelet версии: $KUBELET_VERSION"
  echo "Установка kubectl версии: $KUBECTL_VERSION"
  sudo apt-get install -y kubelet=$KUBELET_VERSION kubectl=$KUBECTL_VERSION
else
  echo "ВНИМАНИЕ: Версии 1.35 не найдены для kubelet или kubectl!"
  echo "Проверьте доступные версии:"
  apt-cache madison kubelet | grep 1.35 || echo "kubelet 1.35 не найден"
  apt-cache madison kubectl | grep 1.35 || echo "kubectl 1.35 не найден"
  echo "Используйте точные версии из вывода выше для установки"
  exit 1
fi
sudo apt-mark hold kubelet kubectl

# 4. Перезагрузка конфигурации systemd
sudo systemctl daemon-reload

# 5. Перезапуск kubelet
sudo systemctl restart kubelet

# 6. Проверка статуса kubelet
sudo systemctl status kubelet
```

**ВАЖНО:** 
- Убедитесь, что флаг `--pod-infra-container-image` был удалён из `/var/lib/kubelet/kubeadm-flags.env` на этом узле на шаге подготовки выше
- Команда `kubeadm upgrade node` автоматически обновит конфигурацию kubelet для работы с новой версией

### Шаг 3: Возврат ноды в планирование (на master-ноде)

**Выполните на master-ноде:**

```bash
# Подключитесь к master-ноде
ssh -i k8s-key master@178.154.197.32

# Верните ноду в строй (замените k8s-worker-1 на нужную ноду)
kubectl uncordon k8s-worker-1

# Проверка:
kubectl get nodes
# Нода должна быть в статусе Ready с версией v1.35.0
```

### Шаг 4: Проверка статуса ноды

**Выполните на master-ноде:**

```bash
# Проверка статуса всех нод
kubectl get nodes -o wide

# Нода должна быть в статусе Ready с новой версией v1.35.0
```

### Повторите шаги 1-4 для каждой следующей worker-ноды

**Порядок обновления worker-нод:**
1. k8s-worker-1 (158.160.67.215, пользователь: node1)
2. k8s-worker-2 (158.160.78.216, пользователь: node2)
3. k8s-worker-3 (158.160.77.191, пользователь: node3)

**ВАЖНО:** Обновляйте ноды последовательно, не параллельно. После обновления каждой ноды проверяйте, что она в статусе Ready перед переходом к следующей.

---

## Финальная проверка кластера

После обновления всех нод (master и все worker-ноды):

**Выполните на master-ноде:**

```bash
# Подключитесь к master-ноде
ssh -i k8s-key master@178.154.197.32

# Проверка версий всех нод (все должны быть v1.35.0)
kubectl get nodes -o wide

# Ожидаемый вывод:
# NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
# k8s-master     Ready    control-plane   Xh    v1.35.0   10.129.0.10   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
# k8s-worker-1   Ready    <none>          Xh    v1.35.0   10.129.0.22   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
# k8s-worker-2   Ready    <none>          Xh    v1.35.0   10.129.0.18   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1
# k8s-worker-3   Ready    <none>          Xh    v1.35.0   10.129.0.31   <none>        Ubuntu 22.04.5 LTS   5.15.0-164-generic   containerd://2.2.1

# Проверка версии kubectl
kubectl version --short

# Проверка системных подов
kubectl get pods --all-namespaces

# Все поды должны быть в статусе Running
kubectl get pods -n kube-system

# Проверка подов Flannel
kubectl get pods -n kube-flannel

# Сохранение статуса кластера после обновления
kubectl get nodes -o wide > outputs/nodes-after-upgrade.txt
```

**Все ноды должны быть в статусе `Ready` с версией v1.35.0.**

---

## Полезные команды для диагностики

### На любой ноде:

```bash
# Проверка версии kubelet на ноде
kubelet --version

# Проверка логов kubelet
sudo journalctl -u kubelet -f

# Проверка статуса компонентов
sudo systemctl status kubelet
sudo systemctl status containerd
```

### На master-ноде:

```bash
# Подробная информация о ноде
kubectl describe node <node-name>

# События в кластере
kubectl get events --sort-by=.metadata.creationTimestamp

# Проверка компонентов control plane
kubectl get pods -n kube-system -o wide
```

---

## Резюме процесса обновления

1. ✅ **Подготовка:** Удаление флага `--pod-infra-container-image` на всех узлах
2. ✅ **Master-нода:** 
   - Обновление kubeadm до 1.35.0
   - Выполнение `kubeadm upgrade plan`
   - Выполнение `kubeadm upgrade apply v1.35.0`
   - Обновление kubelet и kubectl до 1.35.0
3. ✅ **Worker-ноды (по одной):**
   - `kubectl drain` на master-ноде
   - Обновление kubeadm до 1.35.0 на worker-ноде
   - Выполнение `kubeadm upgrade node` на worker-ноде
   - Обновление kubelet и kubectl до 1.35.0 на worker-ноде
   - `kubectl uncordon` на master-ноде
4. ✅ **Проверка:** Все ноды в статусе Ready с версией v1.35.0

**Обновление завершено! Кластер успешно обновлен с версии 1.34.3 до 1.35.0.**
