## Практика с SELinux

### Домашнее задание:

1. Запустить nginx на нестандартном порту 3-мя разными способами:
* переключатели setsebool;
* добавление нестандартного порта в имеющийся тип;
* формирование и установка модуля SELinux.

Формат сдачи:

README с описанием каждого решения (скриншоты и демонстрация приветствуются).


2. Обеспечить работоспособность приложения при включенном selinux.

* развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems;
* выяснить причину неработоспособности механизма обновления зоны (см. README);
* предложить решение (или решения) для данной проблемы;
* выбрать одно из решений для реализации, предварительно обосновав выбор;
* реализовать выбранное решение и продемонстрировать его работоспособность.

Формат сдачи:

README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.

### Выполнение:

### 1. Запуск nginx на нестандартном порту 3-мя разными способами:

Код стенда можно получить из репозитория: https://github.com/Nickmob/vagrant_selinux 

Результатом выполнения команды vagrant up станет созданная виртуальная машина с установленным nginx, который работает на порту TCP 4881. Порт TCP 4881 уже проброшен до хоста. SELinux включен.

```bash
systemctl status firewalld
```

```bash
nginx -t
```

```bash
getenforce
```

Должен отображаться режим Enforcing. Данный режим означает, что SELinux будет блокировать запрещенную активность.

**Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool**

Находим в логах (/var/log/audit/audit.log) информацию о блокировании порта

Копируем время, в которое был записан этот лог, и, с помощью утилиты audit2why смотрим

```bash
grep 1790662879.337:79 /var/log/audit/audit.log | audit2why
```
Утилита audit2why покажет почему трафик блокируется. Исходя из вывода утилиты, мы видим, что нам нужно поменять параметр nis_enabled. 

Включим параметр nis_enabled и перезапустим nginx:

```bash
setsebool -P nis_enabled 1
```

```bash
systemctl restart nginx
```

```bash
systemctl status nginx
```

![IMG1](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/1.png)

Также можно проверить работу nginx из браузера. Заходим в любой браузер на хосте и переходим по адресу
http://127.0.0.1:4881

![IMG2](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/2.png)

Проверить статус параметра можно с помощью команды: 

```bash
getsebool -a | grep nis_enabled
```

Вернём запрет работы nginx на порту 4881 обратно. 
Для этого отключим nis_enabled:

```bash
setsebool -P nis_enabled off
```
После отключения nis_enabled служба nginx снова не запустится.

**Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:**

Поиск имеющегося типа, для http трафика:

```bash
semanage port -l | grep http
```

Добавим порт в тип http_port_t:

```bash
semanage port -a -t http_port_t -p tcp 4881
```

Теперь перезапускаем службу nginx и проверим её работу:

![IMG3](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/3.png)

Приветственная страница в браузере так же открывается.

Удалить нестандартный порт из имеющегося типа можно с помощью команды:

```bash
semanage port -d -t http_port_t -p tcp 4881
```

**Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:**

Посмотрим логи SELinux, которые относятся к Nginx:

```bash
grep nginx /var/log/audit/audit.log
```

Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий работу nginx на нестандартном порту:

```bash
grep nginx /var/log/audit/audit.log | audit2allow -M nginx
```

Audit2allow сформировал модуль, и сообщил нам команду, с помощью которой можно применить данный модуль:

```bash
semodule -i nginx.pp
```

![IMG4](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/4.png)

После добавления модуля nginx запустился без ошибок. При использовании модуля изменения сохранятся после перезагрузки. 

Просмотр всех установленных модулей:

```bash
semodule -l
```

```bash
semodule -r nginx
```

### 2. Обеспечение работоспособность приложения при включенном selinux:

Для того, чтобы развернуть стенд потребуется хост, с установленным git и ansible.

Инструкция по установке Ansible - https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

Выполним клонирование репозитория:

```bash
git clone https://github.com/Nickmob/vagrant_selinux_dns_problems.git
```
Перейдём в каталог со стендом: `cd vagrant_selinux_dns_problems`

Развернём 2 ВМ с помощью vagrant: `vagrant up`

После того, как стенд развернется, проверим ВМ с помощью команды: `vagrant status`

![IMG5](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/5.png)

Подключимся к клиенту: `vagrant ssh client`

Попробуем внести изменения в зону:

```bash
nsupdate -k /etc/named.zonetransfer.key
```

```bash
server 192.168.50.10
```

```bash
zone ddns.lab
```

```bash
update add www.ddns.lab. 60 A 192.168.50.15
```

```bash
send
```

```bash
quit
```

![IMG6](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/6.png)

Изменения внести не получилось. Давайте посмотрим логи SELinux, чтобы понять в чём может быть проблема.

Для этого воспользуемся утилитой audit2why: 

```bash
cat /var/log/audit/audit.log | audit2why
```

Тут мы видим, что на клиенте отсутствуют ошибки. 

**Не закрывая сессию на клиенте**, подключимся к серверу ns01 и проверим логи SELinux:

```bash
vagrant ssh ns01
```

```bash
cat /var/log/audit/audit.log | audit2why
```

![IMG7](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/7.png)

В логах мы видим, что ошибка в контексте безопасности. Целевой контекст `named_conf_t`.

Для сравнения посмотрим существующую зону (`localhost`) и её контекст:

```bash
ls -alZ /var/named/named.localhost
```

У наших конфигов в `/etc/named` вместо типа `named_zone_t` используется тип `named_conf_t`.

Проверим данную проблему в каталоге `/etc/named`:

```bash
ls -laZ /etc/named
```

![IMG8](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/8.png)

Тут мы также видим, что контекст безопасности неправильный. Проблема заключается в том, что конфигурационные файлы лежат в другом каталоге. 

Посмотреть в каком каталоги должны лежать, файлы, чтобы на них распространялись правильные политики SELinux можно с помощью команды: 

```bash
sudo semanage fcontext -l | grep named
```

> /etc/rndc.*              regular file       system_u:object_r:named_conf_t:s0 

> /var/named(/.*)?         all files          system_u:object_r:named_zone_t:s0 

Изменим тип контекста безопасности для каталога `/etc/named`:

```bash
sudo chcon -R -t named_zone_t /etc/named
```

```bash
ls -laZ /etc/named
```

![IMG9](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/9.png)

Попробуем снова внести изменения с клиента:

```bash
nsupdate -k /etc/named.zonetransfer.key
```

```bash
server 192.168.50.10
```

```bash
zone ddns.lab
```

```bash
update add www.ddns.lab. 60 A 192.168.50.15
```

```bash
send
```

```bash
quit
```

```bash
dig www.ddns.lab
```

![IMG10](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/10.png)

Видим, что изменения применились. 

Попробуем перезагрузить хосты и ещё раз сделать запрос с помощью dig: 

```bash
dig @192.168.50.10 www.ddns.lab
```

![IMG11](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/11.png)

Всё правильно. После перезагрузки настройки сохранились. 

Важно, что мы не добавили новые правила в политику для назначения этого контекста в каталоге. Значит, что при перемаркировке файлов контекст вернётся на тот, который прописан в файле политики.

Для того, чтобы вернуть правила обратно, можно ввести команду: 

```bash
restorecon -v -R /etc/named
```

![IMG12](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%2011.%20%D0%9F%D1%80%D0%B0%D0%BA%D1%82%D0%B8%D0%BA%D0%B0%20%D1%81%20SELinux/img/12.png)
