# Занятие 1. Обновление ядра системы
Описание домашнего задания
1) Запустить ВМ c Ubuntu.
2) Обновить ядро ОС на новейшую стабильную версию из mainline-репозитория.
3) Оформить отчет в README-файле в GitHub-репозитории.

**Подключаемся по ssh к созданной виртуальной машины.**

**Перед работами проверим текущую версию ядра:**

C:\Users\User>ssh -p 2222 fox@127.0.0.7

fox@127.0.0.7's password:

Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.8.0-134-generic x86_64)

fox@Ubuntu-server-24:~$ uname -r

6.8.0-134-generic

fox@Ubuntu-server-24:~$ mkdir kernel && cd kernel

**Скачиваем ядро версии v7.1:**

fox@Ubuntu-server-24:~/kernel$ wget https://kernel.ubuntu.com/mainline/v7.1/amd64/linux-headers-7.1.0-070100-generic_7.1.0-070100.202606141628_amd64.deb

2026-07-12 18:50:57 (2.73 MB/s) - ‘linux-headers-7.1.0-070100-generic_7.1.0-070100.202606141628_amd64.deb’ saved [4108018/4108018]

fox@Ubuntu-server-24:~/kernel$ wget https://kernel.ubuntu.com/mainline/v7.1/amd64/linux-headers-7.1.0-070100_7.1.0-070100.202606141628_all.deb

2026-07-12 18:51:37 (4.96 MB/s) - ‘linux-headers-7.1.0-070100_7.1.0-070100.202606141628_all.deb’ saved [14855142/14855142]

fox@Ubuntu-server-24:~/kernel$ wget https://kernel.ubuntu.com/mainline/v7.1/amd64/linux-image-unsigned-7.1.0-070100-generic_7.1.0-070100.202606141628_amd64.deb

2026-07-12 18:51:50 (7.77 MB/s) - ‘linux-image-unsigned-7.1.0-070100-generic_7.1.0-070100.202606141628_amd64.deb’ saved [17490112/17490112]

fox@Ubuntu-server-24:~/kernel$ wget https://kernel.ubuntu.com/mainline/v7.1/amd64/linux-modules-7.1.0-070100

2026-07-12 18:52:30 (9.02 MB/s) - ‘linux-modules-7.1.0-070100-generic_7.1.0-070100.202606141628_amd64.deb’ saved [170117312/170117312]

**Устанавливаем:**

fox@Ubuntu-server-24:~/kernel$ sudo dpkg -i *.deb

**Проверяем, что добавилось:**

fox@Ubuntu-server-24:~/kernel$ ls -al /boot

total 207460

drwxr-xr-x  3 root root     4096 Jul 12 18:59 .

drwxr-xr-x 23 root root     4096 Jul 12 09:21 ..

-rw-r--r--  1 root root   287560 Jun 26 15:31 config-6.8.0-134-generic

-rw-r--r--  1 root root   307299 Jun 14 16:28 config-7.1.0-070100-generic

drwxr-xr-x  5 root root     4096 Jul 12 18:59 grub

lrwxrwxrwx  1 root root       31 Jul 12 18:58 initrd.img -> initrd.img-7.1.0-070100-generic

-rw-r--r--  1 root root 76547680 Jul 12 18:15 initrd.img-6.8.0-134-generic

-rw-r--r--  1 root root 81735534 Jul 12 18:59 initrd.img-7.1.0-070100-generic

lrwxrwxrwx  1 root root       28 Jul 12 09:31 initrd.img.old -> initrd.img-6.8.0-134-generic

-rw-------  1 root root  9128449 Jun 26 15:31 System.map-6.8.0-134-generic

-rw-------  1 root root 11899326 Jun 14 16:28 System.map-7.1.0-070100-generic

lrwxrwxrwx  1 root root       28 Jul 12 18:58 vmlinuz -> vmlinuz-7.1.0-070100-generic

-rw-------  1 root root 15042952 Jun 26 16:36 vmlinuz-6.8.0-134-generic

-rw-------  1 root root 17457664 Jun 14 16:28 vmlinuz-7.1.0-070100-generic

lrwxrwxrwx  1 root root       25 Jul 12 09:31 vmlinuz.old -> vmlinuz-6.8.0-134-generic

fox@Ubuntu-server-24:~/kernel$ sudo reboot

**Выбираем новую версию ядра в GRUB, загружаемся.**

fox@Ubuntu-server-24:~$ uname -r

7.1.0-070100-generic
