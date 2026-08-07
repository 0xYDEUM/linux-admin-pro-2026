#!/bin/bash
# Скрипт настройки NFS-клиента (nfsc)
# Запускать: sudo ./nfsc_script.sh

set -e  # выход при получении ошибки

if [ "$EUID" -ne 0 ]; then
    echo "Скрипт нужно запускать с правами root!"
    exit 1
fi

echo "Установка nfs-common..."
apt update
apt install -y nfs-common

FSTAB_LINE="192.168.50.10:/srv/share /mnt nfs vers=3,proto=tcp,rw,sync,noatime 0 0"

echo "Добавление записи в /etc/fstab (если отсутствует)..."
if ! grep -qF "$FSTAB_LINE" /etc/fstab; then
    echo "$FSTAB_LINE" >> /etc/fstab
    echo "Запись добавлена."
else
    echo "Запись уже существует, пропускаем."
fi

echo "Перечитывание fstab и монтирование..."
systemctl daemon-reload
mount -a

echo "Проверка монтирования:"
mount | grep /mnt || echo "ВНИМАНИЕ: /mnt не смонтирована! Проверьте сеть и сервер NFS."

echo "Готово. Клиент настроен."