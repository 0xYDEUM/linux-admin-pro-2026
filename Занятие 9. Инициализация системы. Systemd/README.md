## Systemd — создание unit-файла

Все дальнейшие действия были проверены при использовании Vagrant 2.4.1,  
VirtualBox v7.0.18. В лабораторной работе используются Vagrant boxes с Ubuntu 22.04.  
Серьёзные отступления от этой конфигурации могут потребовать адаптации с  
вашей стороны.

### Домашнее задание:

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).  
2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта ([https://gist.github.com/cea2k/1318020](https://gist.github.com/cea2k/1318020)).  
3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.

### Выполнение:

#### Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова

Для начала создаём файл с конфигурацией для сервиса в директории /etc/default - из неё сервис будет брать необходимые переменные.

```bash
cat > /etc/default/watchlog  << 'EOF'
# Configuration file for my watchlog service  
# Place it to /etc/default
# File and word in that file that we will be monit 

WORD="ALERT"  
LOG=/var/log/watchlog.log
EOF
```

Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение,  
плюс ключевое слово ‘ALERT’

```bash
cat > /var/log/watchlog.log  << 'EOF'
WHAT A BEAUTIFUL DAY
WHAT A BEAUTIFUL DAY
WHAT A BEAUTIFUL DAY
ALERT ! THE TUCHKA IS HERE
ITS RAINING
EOF
```

Создадим скрипт:  

```bash
cat > /opt/watchlog.sh << 'EOF'
#!/bin/bash

WORD=$1
LOG=$2
DATE=date

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
EOF
```

Команда logger отправляет лог в системный журнал.  
Добавим права на запуск файла:

```bash
chmod +x /opt/watchlog.sh
```

Создадим юнит для сервиса:  

```bash
cat > /etc/systemd/system/watchlog.service << 'EOF'
[Unit]  
Description=My watchlog service

[Service]  
Type=oneshot  
EnvironmentFile=/etc/default/watchlog  
ExecStart=/opt/watchlog.sh $WORD $LOG
EOF
```

Создадим юнит для таймера:  

```bash
cat > /etc/systemd/system/watchlog.timer << 'EOF'
[Unit]  
Description=Run watchlog script every 30 second

[Timer]
OnBootSec=10  
OnUnitActiveSec=30  
Unit=watchlog.service

[Install]  
WantedBy=multi-user.target
EOF
```

Затем достаточно только запустить timer:  

```bash
systemctl start watchlog.timer
```

И убедиться в результате:

```bash
tail -n 1000 /var/log/syslog  | grep word
```  

![IMG1]()

#### Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта

Устанавливаем spawn-fcgi и необходимые для него пакеты: 

```bash
apt-get update
``` 

```bash
apt install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y
``` 

 Сам Init скрипт, который будем переписывать, можно найти здесь: [https://gist.github.com/cea2k/1318020](https://gist.github.com/cea2k/1318020) 

Но перед этим необходимо создать файл с настройками для будущего сервиса в файле /etc/spawn-fcgi/fcgi.conf.  
Он должен получится следующего вида:

```bash
mkdir -p /etc/spawn-fcgi
```

```bash
cat > /etc/spawn-fcgi/fcgi.conf << 'EOF'
# You must set some working options before the "spawn-fcgi" service will work.  
# If SOCKET points to a file, then this file is cleaned up by the init script.  
#  
# See spawn-fcgi(1) for all possible options.  
#  
# Example :  
SOCKET=/var/run/php-fcgi.sock  
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
EOF
```

А сам юнит-файл будет примерно следующего вида:

```bash
cat > /etc/systemd/system/spawn-fcgi.service << 'EOF'
[Unit]  
Description=Spawn-fcgi startup service
After=network.target

[Service]  
Type=simple  
PIDFile=/var/run/spawn-fcgi.pid  
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf  
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS  
KillMode=process

[Install]  
WantedBy=multi-user.target
EOF
```

Убеждаемся, что все успешно работает:

```bash
systemctl start spawn-fcgi  
```

```bash
systemctl status spawn-fcgi
```

![IMG2]()

#### Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно

Установим Nginx из стандартного репозитория:

```bash
apt install nginx -y
```

Для запуска нескольких экземпляров сервиса модифицируем исходный service для использования различной конфигурации, а также PID-файлов. Для этого создадим новый Unit для работы с шаблонами (/etc/systemd/system/nginx@.service):

```bash
cat > /etc/systemd/system/nginx@.service << 'EOF'
# Stop dance for nginx  
# =======================  
#  
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.  
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control  
# and sends SIGTERM (fast shutdown) to the main process.  
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends  
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).  
#  
# nginx signals reference doc:  
# http://nginx.org/en/docs/control.html  
#  
[Unit]  
Description=A high performance web server and a reverse proxy server  
Documentation=man:nginx(8)  
After=network.target nss-lookup.target

[Service]  
Type=forking  
PIDFile=/run/nginx-%I.pid  
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'  
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'  
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload  
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid  
TimeoutStopSec=5  
KillMode=mixed

[Install]  
WantedBy=multi-user.target
EOF
```

Далее необходимо создать два файла конфигурации (/etc/nginx/nginx-first.conf, /etc/nginx/nginx-second.conf). Их можно сформировать из стандартного конфига /etc/nginx/nginx.conf, с модификацией путей до PID-файлов и разделением по портам:

```bash
pid /run/nginx-first.pid;

http {  
…  
	server {  
		listen 9001;  
	}  
#include /etc/nginx/sites-enabled/*;  
….  
}
```

Этого достаточно для успешного запуска сервисов.  
Проверим работу:

```bash
systemctl start nginx@first
```  

```bash
systemctl start nginx@second  
```

```bash
systemctl status nginx@second
```

Проверить можно несколькими способами, например, посмотреть, какие порты слушаются:

```bash
ss -tnulp | grep nginx
```

Или просмотреть список процессов:

```bash
ps afx | grep nginx
```

![IMG3]()

Если мы видим две группы процессов Nginx, то всё в порядке. Если сервисы не стартуют, смотрим их статус, ищем ошибки, проверяем ошибки в /var/log/nginx/error.log, а также в journalctl -u nginx@first.  
