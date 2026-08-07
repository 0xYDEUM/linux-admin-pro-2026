#!/bin/bash
# Скрипт настройки NFS-сервера (nfss)
# Запускать: sudo ./nfss_script.sh

set -e  # выход при получении ошибки

if [ "$EUID" -ne 0 ]; then
    echo "Скрипт нужно запускать с правами root!"
    exit 1
fi

echo "Установка nfs-kernel-server..."
apt update
apt install -y nfs-kernel-server

echo "Текущие слушающие порты (NFS):"
ss -tnplu | grep -E 'nfs|rpc|mountd' || true

echo "Создание каталогов..."
mkdir -p /srv/share/upload
chown -R nobody:nogroup /srv/share
chmod 0777 /srv/share/upload

echo "Настройка /etc/exports..."
cat > /etc/exports << 'EOF'
/srv/share 192.168.50.11/32(rw,sync,root_squash)
EOF

echo "Применение экспорта..."
exportfs -ra
echo "Текущие экспортированные ресурсы:"
exportfs -s

echo "Включение и запуск nfs-server..."
systemctl enable --now nfs-server

echo "Готово. Сервер NFS настроен."