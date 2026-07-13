# Домашнее задание: работа с mdadm

Задание:

• Добавить в виртуальную машину несколько дисков

• Собрать RAID-0/1/5/10 на выбор

• Сломать и починить RAID

• Создать GPT таблицу, пять разделов и смонтировать их в системе.

Выполнение: 

1. Посмотрим, какие блочные устройства у нас есть:

```bash
sudo lshw -short | grep disk
```

![Screen1](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%202.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20mdadm/img/1.png)

2. Занулим на всякий случай суперблоки:

```bash
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
```

3. Создадим RAID-5 следующей командой:

```bash
sudo mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}
```

![Screen2](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%202.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20mdadm/img/2.png)

4. Проверим, что RAID собрался нормально:

```bash
cat /proc/mdstat
```

```bash
mdadm -D /dev/md0
```

![Screen3](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%202.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20mdadm/img/3.png)

5. Теперь "сломаем" наш RAID:

```bash
sudo mdadm /dev/md0 --fail /dev/sdc
```

6. Посмотрим, как это отразилось на RAID:

```bash
cat /proc/mdstat
```

```bash
sudo mdadm -D /dev/md0
```

![Screen4](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%202.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20mdadm/img/4.png)

7. Удалим “сломанный” диск из массива:

```bash
sudo mdadm /dev/md0 --remove /dev/sdc
```

8. А теперь добавим обратно, будто бы вставили новый рабочий диск:

```bash
sudo mdadm /dev/md0 --add /dev/sdc
```

9. Процесс rebuild-а можно увидеть в выводе следующих команд:

```bash
cat /proc/mdstat
```

```bash
sudo mdadm -D /dev/md0
```

![Screen5](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%202.%20%D0%A0%D0%B0%D0%B1%D0%BE%D1%82%D0%B0%20%D1%81%20mdadm/img/5.png)

10. 

```bash

```

11. 
