## Первые шаги с Ansible

### Домашнее задание:

Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере, используя Ansible, необходимо развернуть nginx со следующими условиями:

- необходимо использовать модуль yum/apt;

- конфигурационные файлы должны быть взяты из шаблона jinja2 с переменными;

- после установки nginx должен быть в режиме enabled в systemd;

- должен быть использован notify для старта nginx после установки;

- сайт должен слушать на нестандартном порту — 8080, для этого использовать переменные в Ansible.


### Выполнение:

Состав ПО: VirtualBox, Vagrant, Ansible, Python.

Создайте каталог Ansible и положите в него этот [Vagrantfile]()

Поднимите управляемый хост командой `vagrant up` и убедитесь, что все прошло успешно и есть доступ по ssh.

Для подключения к хосту `nginx` c `Ansible` нам необходимо будет передать множество параметров - это особенность Vagrant.

Узнать параметры подключения к ВМ можно с помощью команды:

```bash
vagrant ssh-config
```

В текущем каталоге создадим файл ansible.cfg со следующим содержанием:

```bash
[defaults]
inventory = staging/hosts
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False
```

Создадим inventory файл `./staging/hosts`:

```bash
[web]
nginx ansible_host=127.0.0.1 ansible_port=2222 ansible_private_key_file=.vagrant/machines/nginx/virtualbox/private_key

```

Проверка связи:

```bash
ansible nginx -m ping
```

![IMG1]()

Добавим шаблон для конфига `nginx` по пути `templates/nginx.conf.j2`:

```jinja2
# {{ ansible_managed }}
events {
    worker_connections 1024;
}

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}
```

Результирующий файл [nginx.yml]() 

Теперь запускаем:

```bash
ansible-playbook nginx.yml
```

![IMG2]()

Из консоли ВМ выполним команду и убедимся, что сайт доступен:

```bash
curl http://192.168.11.150:8080
```

![IMG3]()