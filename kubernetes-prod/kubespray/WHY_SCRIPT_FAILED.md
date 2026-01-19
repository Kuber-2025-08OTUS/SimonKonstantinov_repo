# Почему скрипт не сохранил vms-ha-info.txt

## Проблема

Скрипт `create-vms-ha.sh` создал ВМ, но не сохранил файл `kubespray/vms-ha-info.txt`.

## Причина

Скрипт сохраняет информацию о ВМ в `kubespray/vms-ha-info.txt` только **если директория kubespray уже существует**.

См. код скрипта (строки 235-238):
```bash
# Сохранение информации в файл проекта
if [ -d "$PROJECT_DIR/kubespray" ]; then
    cp /tmp/k8s-ha-vms.csv "$PROJECT_DIR/kubespray/vms-ha-info.txt" 2>/dev/null || true
    echo "Информация сохранена в: $PROJECT_DIR/kubespray/vms-ha-info.txt"
fi
```

**Если директория `kubespray/` не существовала на момент запуска скрипта, файл не создается!**

## Решение

### Вариант 1: Файл уже создан

Я автоматически создал файл `kubespray/vms-ha-info.txt` на основе существующих ВМ.

Проверьте:
```bash
cat kubespray/vms-ha-info.txt
```

### Вариант 2: Перезапустить скрипт (если нужны новые ВМ)

Перед запуском скрипта убедитесь, что директория существует:
```bash
cd /home/konstsima/SimonKonstantinov_repo/kubernetes-prod
mkdir -p kubespray
./scripts/create-vms-ha.sh
```

### Вариант 3: Создать файл вручную (если ВМ уже созданы)

Используйте информацию о существующих ВМ:
```bash
# Получить информацию о ВМ
yc compute instance list --format json | jq -r '.[] | select(.name | startswith("k8s-ha-")) | "\(.name),\(.network_interfaces[0].primary_v4_address.one_to_one_nat.address // "N/A"),\(.network_interfaces[0].primary_v4_address.address)"'
```

## Текущее состояние

✅ ВМ созданы (5 штук): k8s-ha-master-1, k8s-ha-master-2, k8s-ha-master-3, k8s-ha-worker-1, k8s-ha-worker-2

✅ Файл `kubespray/vms-ha-info.txt` создан с правильными IP-адресами

## Следующие шаги

Используйте IP-адреса из `kubespray/vms-ha-info.txt` для настройки inventory файла kubespray.
