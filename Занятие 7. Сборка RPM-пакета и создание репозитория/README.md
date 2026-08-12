## Домашнее задание: размещаем свой RPM в своем репозитории

## Задание:

1) Создать свой RPM пакет (можно взять свое приложение, либо собрать с определенными опциями).  
2) Создать свой репозиторий и разместить там ранее собранный RPM.

Реализовать это все либо в Vagrant, либо развернуть у себя через Nginx и дать ссылку на репозиторий.

Все дальнейшие действия были проверены при использовании Vagrant 2.4.9,  
VirtualBox v7.2.14 и образа [AlmaLinux 9.3](https://app.vagrantup.com/almalinux/boxes/9/versions/9.3.20231118).

## Создать свой RPM пакет

* Для данного задания нам понадобятся следующие установленные пакеты:  

```bash
dnf install -y wget rpmdevtools rpm-build createrepo dnf-utils cmake gcc git nano
```

* Для примера возьмем пакет Nginx и соберем его с дополнительным модулем ngx_broli  

* Загрузим SRPM пакет Nginx для дальнейшей работы над ним:  

```bash 
mkdir rpm && cd rpm  
```

```bash 
yumdownloader --source nginx
```

* При установке такого пакета в домашней директории создается дерево каталогов для сборки, далее поставим все зависимости для сборки пакета Nginx:  

```bash 
rpm -Uvh nginx*.src.rpm
```

```bash 
yum-builddep nginx
```

* Также нужно скачать исходный код модуля ngx_brotli — он  
потребуется при сборке: 

```bash 
cd /root  
```

```bash 
git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli  
```

```bash 
cd ngx_brotli/deps/brotli  
```

```bash 
mkdir out && cd out
```

* Собираем модуль ngx_brotli:

```bash
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
```

![IMG1](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/1.png)

```bash 
cmake --build . --config Release -j 2 --target brotlienc  
```

![IMG2](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/2.png)

```bash 
cd ../../../..
```

```bash 
cd ~/rpmbuild/SPECS/  
```

```bash
nano nginx.spec
```

* Нужно поправить сам spec файл, чтобы Nginx собирался с необходимыми нам опциями: находим секцию с параметрами `configure` (до условий if) и добавляем указание на модуль (не забудьте указать завершающий обратный слэш):  

```bash
--add-module=/root/ngx_brotli \
```

![IMG3](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/3.png)

* По этой [ссылке](https://nginx.org/ru/docs/configure.html) можно посмотреть все доступные опции для сборки.

* Теперь можно приступить к сборке RPM пакета:

```bash 
rpmbuild -ba nginx.spec -D 'debug_package %{nil}' 
```

![IMG4](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/4.png)

* Убедимся, что пакеты создались:  

```bash 
ll rpmbuild/RPMS/x86_64/
```

![IMG5](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/5.png)

* Копируем пакеты в общий каталог: 

```bash 
cp ~/rpmbuild/RPMS/noarch/* ~/rpmbuild/RPMS/x86_64/
```

```bash 
cd ~/rpmbuild/RPMS/x86_64
```

* Теперь можно установить наш пакет и убедиться, что nginx работает:

```bash 
dnf localinstall *.rpm  
```

```bash 
systemctl start nginx 
``` 

```bash 
systemctl status nginx
```

![IMG6](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/6.png)

* Далее мы будем использовать его для доступа к своему репозиторию.

## Создать свой репозиторий и разместить там ранее собранный RPM

* Теперь приступим к созданию своего репозитория. Директория для статики у Nginx по умолчанию /usr/share/nginx/html. Создадим там каталог repo:

```bash 
mkdir /usr/share/nginx/html/repo
```

* Копируем туда наши собранные RPM-пакеты:

```bash 
cp ~/rpmbuild/RPMS/x86_64/*.rpm /usr/share/nginx/html/repo/
```

* Инициализируем репозиторий командой:

```bash 
createrepo /usr/share/nginx/html/repo/  
```

> Directory walk started  
> Directory walk done - 10 packages < Видим, что в репозитории 10 пакетов  
> Temporary output repo path: /usr/share/nginx/html/repo/.repodata/  
> Preparing sqlite DBs < Обратите внимание что используется `sqlite`  
> Pool started (with 5 workers)  
> Pool finished

* Для прозрачности настроим в NGINX доступ к листингу каталога. В файле /etc/nginx/nginx.conf в блоке server добавим следующие директивы:

```bash
nano /etc/nginx/nginx.conf
```

```bash
index index.html index.htm;  
autoindex on;
```

* Проверяем синтаксис и перезапускаем NGINX:  

```bash 
nginx -t
```

> nginx: the configuration file /etc/nginx/nginx.conf syntax is ok  
> nginx: configuration file /etc/nginx/nginx.conf test is successful  

```bash 
nginx -s reload
```

* Теперь ради интереса можно посмотреть в браузере или с помощью curl:  

```bash 
lynx http://localhost/repo/  
```

```bash 
curl -a http://localhost/repo/
```

![IMG7](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/7.png)

* Все готово для того, чтобы протестировать репозиторий.  

* Добавим его в `/etc/yum.repos.d`:  

```bash 
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]  
name=otus-linux  
baseurl=http://localhost/repo  
gpgcheck=0  
enabled=1  
EOF
```

* Убедимся, что репозиторий подключился и посмотрим, что в нем есть:  

```bash 
dnf repolist enabled | grep otus  
```

* Добавим пакет в наш репозиторий: 

```bash 
cd /usr/share/nginx/html/repo/ 
```

```bash 
wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm
```

* Обновим список пакетов в репозитории:  

```bash 
createrepo /usr/share/nginx/html/repo/
```

```bash
dnf makecache  
```

```bash 
dnf list | grep otus  
```

![IMG8](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/8.png)

* Так как Nginx у нас уже стоит, установим репозиторий percona-release:

```bash 
dnf install -y percona-release.noarch
```

![IMG9](https://github.com/0xYDEUM/linux-admin-pro-2026/blob/main/%D0%97%D0%B0%D0%BD%D1%8F%D1%82%D0%B8%D0%B5%207.%20%D0%A1%D0%B1%D0%BE%D1%80%D0%BA%D0%B0%20RPM-%D0%BF%D0%B0%D0%BA%D0%B5%D1%82%D0%B0%20%D0%B8%20%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%20%D1%80%D0%B5%D0%BF%D0%BE%D0%B7%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D1%8F/img/9.png)

* **Все прошло успешно.** В случае, если вам потребуется обновить репозиторий (а это делается при каждом добавлении файлов) снова, то выполните команду:

```bash
createrepo /usr/share/nginx/html/repo/.
```  
