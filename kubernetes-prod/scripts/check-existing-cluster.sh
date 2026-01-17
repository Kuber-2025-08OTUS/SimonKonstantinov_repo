#!/bin/bash
# Скрипт для проверки существующего кластера на ВМ

set -e

echo "=== Проверка существующего кластера Kubernetes ==="
echo ""
echo "Укажите IP-адрес или имя ВМ для проверки:"
read -r VM_NAME_OR_IP

if [ -z "$VM_NAME_OR_IP" ]; then
    echo "Использование: $0 <VM_IP_OR_NAME>"
    exit 1
fi

echo ""
echo "=== Проверка компонентов на $VM_NAME_OR_IP ==="
echo ""

# Проверка через SSH (если доступен)
if command -v ssh &> /dev/null; then
    echo "Попытка подключения через SSH..."
    ssh "$VM_NAME_OR_IP" 'bash -s' << 'EOF'
        echo "=== Версии компонентов ==="
        echo -n "kubeadm: "
        kubeadm version 2>/dev/null || echo "не установлен"
        
        echo -n "kubectl: "
        kubectl version --client --short 2>/dev/null || echo "не установлен"
        
        echo -n "kubelet: "
        kubelet --version 2>/dev/null || echo "не установлен"
        
        echo -n "containerd: "
        containerd --version 2>/dev/null || echo "не установлен"
        
        echo ""
        echo "=== Статус сервисов ==="
        systemctl is-active containerd 2>/dev/null && echo "✓ containerd активен" || echo "✗ containerd не активен"
        systemctl is-active kubelet 2>/dev/null && echo "✓ kubelet активен" || echo "✗ kubelet не активен"
        
        echo ""
        echo "=== Проверка кластера ==="
        if kubectl get nodes &> /dev/null; then
            echo "✓ Кластер инициализирован"
            echo ""
            echo "Ноды кластера:"
            kubectl get nodes -o wide
            echo ""
            echo "Версия кластера:"
            kubectl version --short
        else
            echo "✗ Кластер не инициализирован или недоступен"
        fi
        
        echo ""
        echo "=== Проверка ресурсов ==="
        echo "CPU: $(nproc) ядер"
        echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
        echo "Disk: $(df -h / | tail -1 | awk '{print $4}') свободно"
        
        echo ""
        echo "=== Проверка swap ==="
        swapon --show || echo "✓ Swap отключен (OK)"
        
        echo ""
        echo "=== Проверка параметров ядра ==="
        sysctl net.bridge.bridge-nf-call-iptables 2>/dev/null || echo "✗ Параметр не настроен"
        sysctl net.ipv4.ip_forward 2>/dev/null || echo "✗ Параметр не настроен"
EOF
else
    echo "SSH не доступен. Выполните команды вручную на ВМ:"
    echo ""
    echo "kubeadm version"
    echo "kubectl version --client"
    echo "kubelet --version"
    echo "containerd --version"
    echo "systemctl status kubelet"
    echo "systemctl status containerd"
    echo "kubectl get nodes -o wide"
fi
