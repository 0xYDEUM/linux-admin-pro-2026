# Домашнее задание: работа с ZFS

### Задание:

1.	Определить алгоритм с наилучшим сжатием:

•	Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);

•	создать 4 файловых системы на каждой применить свой алгоритм сжатия;

•	для сжатия использовать либо текстовый файл, либо группу файлов.

2.	Определить настройки пула.

С помощью команды zfs import собрать pool ZFS.

Командами zfs определить настройки:

    - размер хранилища;

    - тип pool;

    - значение recordsize;

    - какое сжатие используется;

    - какая контрольная сумма используется.

3.	Работа со снапшотами:

•	скопировать файл из удаленной директории;

•	восстановить файл локально. zfs receive;

•	найти зашифрованное сообщение в файле secret_message.

### Выполнение: 

1. Определение алгоритма с наилучшим сжатием

Смотрим список всех дисков, которые есть в виртуальной машине: `lsblk`

Установим пакет утилит для ZFS:

```bash
apt install zfsutils-linux
```

Создаём пул из двух дисков в режиме RAID 1:

```bash
zpool create fox1 mirror /dev/sdb /dev/sdc
```

Создадим ещё 3 пула:

```bash
zpool create fox2 mirror /dev/sdd /dev/sde
```

```bash
zpool create fox3 mirror /dev/sdf /dev/sdg
```

```bash
zpool create fox4 mirror /dev/sdh /dev/sdi
```

Смотрим информацию о пулах:


```bash
zpool list
```

![Screen1](1.png)

Команда zpool status показывает информацию о каждом диске, состоянии сканирования и об ошибках чтения, записи и совпадения хэш-сумм. Команда zpool list показывает информацию о размере пула, количеству занятого и свободного места, дедупликации и т.д. 

Добавим разные алгоритмы сжатия в каждую файловую систему:

•	Алгоритм lzjb: `zfs set compression=lzjb fox1`

•	Алгоритм lz4:  `zfs set compression=lz4 fox2`

•	Алгоритм gzip: `zfs set compression=gzip-9 fox3`

•	Алгоритм zle:  `zfs set compression=zle fox4`

Проверим, что все файловые системы имеют разные методы сжатия:

```bash
zfs get all | grep compression
```

Сжатие файлов будет работать только с файлами, которые были добавлены после включение настройки сжатия. 

Скачаем один и тот же текстовый файл во все пулы: 

```bash
for i in {1..4}; do wget -P /fox$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```

Проверим, что файл был скачан во все пулы:

```bash
ls -l /fox*
```

Уже на этом этапе видно, что самый оптимальный метод сжатия у нас используется в пуле fox3.

Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:


```bash
zfs list
```

```bash
zfs get all | grep compressratio | grep -v ref
```

![Screen2](2.png)

Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.

2. Определение настроек пула

Скачиваем архив в домашний каталог: 

```bash
wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
```

Разархивируем его:

```bash
tar -xzvf archive.tar.gz
```

Проверим, возможно ли импортировать данный каталог в пул:

```bash
zpool import -d zpoolexport/
```

Данный вывод показывает нам имя пула, тип raid и его состав. 

Сделаем импорт данного пула к нам в ОС:

```bash
zpool import -d zpoolexport/ otus
```

![Screen3](3.png)

```bash
zpool status
```

![Screen4](4.png)

Команда `zpool status` выдаст нам информацию о составе импортированного пула.

Если у Вас уже есть пул с именем otus, то можно поменять его имя во время импорта: 

```bash
zpool import -d zpoolexport/ otus newotus
```

Далее нам нужно определить настройки: `zpool get all otus`

Запрос сразу всех параметром файловой системы: `zfs get all otus`

```bash
zfs get all otus
```

C помощью команды grep можно уточнить конкретный параметр, например:
Размер: 

```bash
zfs get available otus
```
Тип:

```bash
zfs get readonly otus
```

По типу FS мы можем понять, что позволяет выполнять чтение и запись

Значение recordsize: 

```bash
zfs get recordsize otus
```

Тип сжатия (или параметр отключения): zfs get compression fox

```bash
zfs get compression otus
```

Тип контрольной суммы:

```bash
zfs get checksum otus
```

![Screen5](5.png)

3. Работа со снапшотом, поиск сообщения от преподавателя

Скачаем файл, указанный в задании:

```bash
wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```

Восстановим файловую систему из снапшота:

```bash
zfs receive otus/test@today < otus_task2.file
```

Далее, ищем в каталоге /otus/test файл с именем “secret_message”:

```bash
find /otus/test -name "secret_message"
```

Смотрим содержимое найденного файла:

```bash
cat /otus/test/task1/file_mess/secret_message
```

![Screen6](6.png)

Тут мы видим ссылку на курс OTUS, задание выполнено.