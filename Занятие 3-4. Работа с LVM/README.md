# Домашнее задание: работа с LVM

### Задание:

На виртуальной машине с Ubuntu 24.04 и LVM.

1. Уменьшить том под / до 8G.

2. Выделить том под /home.

3. Выделить том под /var - сделать в mirror.

4. /home - сделать том для снапшотов.

5. Прописать монтирование в fstab. Попробовать с разными опциями и разными файловыми системами (на выбор).

6. Работа со снапшотами:
	a. сгенерить файлы в /home/;
	b. снять снапшот;
	c. удалить часть файлов;
	d. восстановится со снапшота.

### Выполнение: 

1. Уменьшить том под / до 8G.

Подготовим временный том для / раздела:

```bash
pvcreate /dev/sdb
```

```bash
vgcreate vg_root /dev/sdb
```

```bash
lvcreate -n lv_root -l +100%FREE /dev/vg_root
```

Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные:

```bash
mkfs.ext4 /dev/vg_root/lv_root
```

```bash
mount /dev/vg_root/lv_root /mnt
```

![Screen1](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%203-4.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20LVM/img/1.png)

Этой командой копируем все данные с / раздела в /mnt:

```bash
rsync -avxHAX --progress / /mnt/
```

Проверить что скопировалось можно командой:

```bash
ls /mnt
```

Затем сконфигурируем grub для того, чтобы при старте перейти в новый /.

Сымитируем текущий root, сделаем в него chroot и обновим grub:

```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
```

```bash
chroot /mnt/
```

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

Обновим образ initrd:

```bash
update-initramfs -u
```

![Screen2](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%203-4.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20LVM/img/2.png)

Посмотрим картину с дисками после перезагрузки:

```bash
lsblk
```

Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем старый LV размером в 10G и создаём новый на 8G:

```bash
lvremove /dev/ubuntu-vg/ubuntu-lv
```

```bash
lvcreate -n ubuntu-vg/ubuntu-lv -L 8G /dev/ubuntu-vg
```

Проделываем на нем те же операции, что и в первый раз:

```bash
mkfs.ext4 /dev/ubuntu-vg/ubuntu-lv
```

```bash
mount /dev/ubuntu-vg/ubuntu-lv /mnt
```

```bash
rsync -avxHAX --progress / /mnt/
```

Так же как в первый раз cконфигурируем grub

```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
```

```bash
chroot /mnt/
```

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

```bash
update-initramfs -u
```

2. Выделить том под /var - сделать в mirror + прописать монтирование в fstab.

На свободных дисках создаем зеркало:

```bash
pvcreate /dev/sdc /dev/sdd
```

```bash
vgcreate vg_var /dev/sdc /dev/sdd
```

```bash
lvcreate -L 950M -m1 -n lv_var vg_var
```

Создаем на нем ФС и перемещаем туда /var:

```bash
mkfs.ext4 /dev/vg_var/lv_var
```

```bash
mount /dev/vg_var/lv_var /mnt
```

```bash
cp -aR /var/* /mnt/
```

Дополнительно сохраняем содержимое старого var:

```bash
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```

Монтируем новый var в каталог /var:

```bash
umount /mnt
```

```bash
mount /dev/vg_var/lv_var /var
```

Правим fstab для автоматического монтирования /var:

```bash
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

После чего можно успешно перезагружаться в новый (уменьшенный root) и удалять временную Volume Group:

```bash
lvremove /dev/vg_root/lv_root
```

```bash
vgremove /dev/vg_root
```

```bash
pvremove /dev/sdb
```

![Screen3](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%203-4.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20LVM/img/3.png)

3. Выделить том под /home + прописать монтирование в fstab.

```bash
lvcreate -n lv_home -L 2G /dev/ubuntu-vg
```

```bash
mkfs.ext4 /dev/ubuntu-vg/lv_home
```

```bash
mount /dev/ubuntu-vg/lv_home /mnt/
```

```bash
cp -aR /home/* /mnt/
```

```bash
rm -rf /home/*
```

```bash
umount /mnt
```

```bash
mount /dev/ubuntu-vg/lv_home /home/
```

Правим fstab для автоматического монтирования /home:

```bash
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

![Screen4](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%203-4.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20LVM/img/4.png)

4. /home - делаем том для снапшотов и работаем с ними:

Генерируем файлы в /home/:

```bash
touch /home/file{1..20}
```

Снять снапшот:

```bash
lvcreate -L 100MB -s -n home_snap /dev/ubuntu-vg/lv_home
```

Удалить часть файлов:

```bash
rm -f /home/file{11..20}
```

Процесс восстановления из снапшота:

```bash
umount /home
```

```bash
lvconvert --merge /dev/ubuntu-vg/home_snap
```

```bash
mount /dev/mapper/ubuntu--vg-lv_home /home
```

```bash
ls -al /home
```

![Screen5](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%203-4.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20LVM/img/5.png)

Файлы успешно восстановлены с помощью снапшота.
