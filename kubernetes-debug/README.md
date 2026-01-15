# Kubernetes Debug - Домашнее задание

## Описание

Данное домашнее задание демонстрирует использование эфемерных контейнеров и `kubectl debug` для отладки подов и нод в Kubernetes.

## Структура файлов

- `nginx-distroless-pod.yaml` - манифест пода с distroless образом nginx
- `ls-nginx-output.txt` - вывод команды `ls -la /etc/nginx` из эфемерного контейнера
- `tcpdump-output.txt` - вывод команды `tcpdump` с перехватом сетевых пакетов
- `node-logs-output.txt` - логи пода, полученные через отладочный под ноды
- `strace-output.txt` - вывод команды `strace` для корневого процесса nginx (задание с *)

## Выполненные шаги

### 1. Создание пода с distroless образом

Создан манифест `nginx-distroless-pod.yaml` с использованием образа `kyos0109/nginx-distroless`.

**Применение манифеста:**
```bash
kubectl apply -f nginx-distroless-pod.yaml
```

**Проверка статуса:**
```bash
kubectl get pod nginx-distroless
```

### 2. Создание эфемерного контейнера для отладки пода

Создан эфемерный контейнер с доступом к пространству имен PID основного контейнера:

```bash
kubectl debug -it nginx-distroless --image=busybox --target=nginx -- sh
```

**Параметры:**
- `--target=nginx` - указывает целевой контейнер для разделения PID namespace
- `--image=busybox` - образ для отладочного контейнера
- `-it` - интерактивный режим с TTY

### 3. Доступ к файловой системе отлаживаемого контейнера

Из эфемерного контейнера получен доступ к файловой системе основного контейнера через общий PID namespace.

**Команда для просмотра содержимого /etc/nginx:**
```bash
ls -la /proc/1/root/etc/nginx
```

Результат сохранен в `ls-nginx-output.txt`.

### 4. Запуск tcpdump в отладочном контейнере

В эфемерном контейнере запущена команда для перехвата сетевых пакетов:

```bash
kubectl debug -it nginx-distroless --image=nicolaka/netshoot --target=nginx -- tcpdump -nn -i any -e port 80
```

**Параметры tcpdump:**
- `-nn` - не разрешать имена хостов и портов
- `-i any` - слушать на всех интерфейсах
- `-e` - показывать заголовок канального уровня
- `port 80` - фильтр по порту 80

### 5. Выполнение сетевых запросов к nginx

Пока tcpdump работал, выполнены несколько HTTP-запросов к nginx:

```bash
# Из другого терминала или контейнера
kubectl exec -it nginx-distroless -- wget -O- http://localhost:80
```

Или через port-forward:
```bash
kubectl port-forward nginx-distroless 8080:80
curl http://localhost:8080
```

Результаты перехвата пакетов сохранены в `tcpdump-output.txt`.

### 6. Создание отладочного пода для ноды

Создан отладочный под для ноды, на которой запущен под с distroless nginx:

```bash
# Получаем имя ноды
NODE_NAME=$(kubectl get pod nginx-distroless -o jsonpath='{.spec.nodeName}')

# Создаем отладочный под для ноды
kubectl debug node/$NODE_NAME -it --image=busybox
```

Или напрямую:
```bash
kubectl debug node/<node-name> -it --image=busybox
```

### 7. Доступ к логам пода через файловую систему ноды

Из отладочного пода ноды получен доступ к логам:

**Команда для получения логов:**
```bash
kubectl exec -it <node-debug-pod> -c debugger -- cat /host/var/log/pods/<namespace>_<pod-name>_<pod-uid>/<container-name>/0.log
```

**Пример:**
```bash
kubectl exec -it node-debugger-xxx -c debugger -- cat /host/var/log/pods/default_nginx-distroless_<uid>/nginx/0.log
```

Результаты сохранены в `node-logs-output.txt`.

## Задание с *: Использование strace

Для выполнения `strace` для корневого процесса nginx необходимо:

### Шаги выполнения:

1. **Создать эфемерный контейнер с образом, содержащим strace:**
   ```bash
   kubectl debug -it nginx-distroless --image=busybox --target=nginx -- sh
   ```

2. **Установить strace в отладочном контейнере** (если его нет):
   - В busybox strace может отсутствовать, поэтому используем образ с strace:
   ```bash
   kubectl debug -it nginx-distroless --image=alpine --target=nginx -- sh
   ```
   Затем в контейнере:
   ```bash
   apk add --no-cache strace
   ```

3. **Найти PID корневого процесса nginx:**
   ```bash
   ps aux | grep nginx
   ```
   Обычно это процесс с PID 1 (так как мы в том же PID namespace).

4. **Запустить strace:**
   ```bash
   strace -p 1 -f -e trace=network,file,process
   ```

   **Параметры:**
   - `-p 1` - отслеживать процесс с PID 1
   - `-f` - отслеживать дочерние процессы
   - `-e trace=network,file,process` - фильтр по типам системных вызовов

5. **Выполнить запрос к nginx** (из другого терминала):
   ```bash
   kubectl exec nginx-distroless -- wget -O- http://localhost:80
   ```

6. **Остановить strace** (Ctrl+C) и сохранить вывод.

### Альтернативный способ (одной командой):

```bash
kubectl debug nginx-distroless --image=alpine --target=nginx -- sh -c "apk add --no-cache strace > /dev/null 2>&1 && strace -p 1 -f -e trace=network,file,process -o /tmp/strace.log & sleep 5 && kill %1 && cat /tmp/strace.log"
```

Или с использованием образа, уже содержащего strace:
```bash
kubectl debug nginx-distroless --image=nicolaka/netshoot --target=nginx -- strace -p 1 -f -e trace=network,file,process
```

### Важные моменты:

- **PID namespace sharing**: Использование `--target=nginx` критично, так как это позволяет видеть процессы основного контейнера в том же PID namespace
- **Права доступа**: Для strace требуются соответствующие capabilities (CAP_SYS_PTRACE)
- **Образ отладочного контейнера**: Не все образы содержат strace, поэтому может потребоваться его установка или использование специализированного образа

Результаты strace сохранены в `strace-output.txt`.
