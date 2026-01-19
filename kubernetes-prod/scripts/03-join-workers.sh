#!/bin/bash
# Скрипт для присоединения worker-нод к кластеру
# Используйте актуальную команду kubeadm join из вывода kubeadm init

set -e

# Актуальная команда join (обновлена после инициализации кластера)
JOIN_COMMAND="kubeadm join 10.129.0.3:6443 --token i8yglu.rmfyl2eii4hg9qp1 --discovery-token-ca-cert-hash sha256:584cb2940ffb2d8be6b6712c9bac205d3d3d2a85b7eb164b3dc8483df658d81b"

echo "=== Присоединение worker-нод к кластеру ==="
echo ""
echo "Команда join:"
echo "$JOIN_COMMAND"
echo ""
echo "ВНИМАНИЕ: Этот скрипт должен выполняться на каждой worker-ноде отдельно!"
echo ""
echo "Для выполнения:"
echo "1. Подключитесь к worker-ноде:"
echo "   ssh -i k8s-key node1@158.160.90.73  # для worker-1"
echo "   ssh -i k8s-key node2@158.160.77.22  # для worker-2"
echo "   ssh -i k8s-key node3@158.160.73.156  # для worker-3"
echo ""
echo "2. Выполните команду join с sudo:"
echo "   sudo $JOIN_COMMAND"
echo ""
echo "Или выполните команду напрямую:"
echo ""
echo "sudo $JOIN_COMMAND"