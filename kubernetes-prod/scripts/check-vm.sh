#!/bin/bash
# Скрипт для проверки состояния ВМ и зависимостей

set -e

echo "=== Проверка ВМ в Yandex Cloud ==="
yc compute instance list --format table

echo ""
echo "=== Проверка доступности ВМ ==="
echo "Укажите IP-адрес ВМ для проверки (или нажмите Enter для пропуска):"
read -r VM_IP

if [ -n "$VM_IP" ]; then
    echo "Проверка подключения к $VM_IP..."
    if ping -c 1 "$VM_IP" &> /dev/null; then
        echo "✓ ВМ доступна по сети"
    else
        echo "✗ ВМ недоступна по сети"
    fi
fi

echo ""
echo "=== Для проверки зависимостей на ВМ выполните на каждой ВМ: ==="
echo ""
echo "ssh <USER>@<VM_IP> 'bash -s' << 'EOF'"
echo "  echo '=== Проверка компонентов ==='"
echo "  kubeadm version 2>/dev/null || echo 'kubeadm не установлен'"
echo "  kubectl version --client 2>/dev/null || echo 'kubectl не установлен'"
echo "  kubelet --version 2>/dev/null || echo 'kubelet не установлен'"
echo "  containerd --version 2>/dev/null || echo 'containerd не установлен'"
echo ""
echo "  echo '=== Проверка сервисов ==='"
echo "  systemctl is-active containerd 2>/dev/null || echo 'containerd не активен'"
echo "  systemctl is-active kubelet 2>/dev/null || echo 'kubelet не активен'"
echo ""
echo "  echo '=== Проверка swap ==='"
echo "  swapon --show || echo 'Swap отключен (OK)'"
echo ""
echo "  echo '=== Проверка параметров ядра ==='"
echo "  sysctl net.bridge.bridge-nf-call-iptables"
echo "  sysctl net.ipv4.ip_forward"
echo ""
echo "  echo '=== Проверка ресурсов ==='"
echo "  echo 'CPU:' \$(nproc)"
echo "  echo 'RAM:' \$(free -h | grep Mem | awk '{print \$2}')"
echo "EOF"
