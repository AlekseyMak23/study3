1) Обновить ядро ОС из репозитория ELRepo
1.1 Создал Vagrantfile, в котором указал параметры вм
1.2 Запустил вм командой - vagrant up, подключился к вм - vagrant ssh, проверил версию ядра - uname -r
1.3 Подключил репозиторий - https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm, установил
1.4 Установил последнее ядро из репозитория - sudo yum --enablerepo elrepo-kernel install kernel-ml -y
1.5 Обновил конфигурацию загрузчика - sudo grub2-mkconfig -o /boot/grub2/grub.cfg
1.6 Загрузка нового ядра по умолчанию - sudo grub2-set-default 0
1.7 Перезагрузил вм и проверил версию ядра - uname -r

2) Создать Vagrant box c помощью Packer
2.1 Создал папку packer/ перешел в нее - mkdir packer/cd packer
2.2 В каталоге packer создал файл centos.json, добавил в него содержимое из методички (позже внес ряд исправлений)
2.3 Создал каталоги http и scripts, в них соответственно создал файлы ks.cfg и stage-1-kernel-update.sh,stage-2-clean.sh, вставил содержимое
2.4 В каталоге выполнил команду создания образа системы:
alex@Ubuntu-Mak:~/packer$ packer build centos.json
2.5 Получил сообщение вида:
==> Builds finished. The artifacts of successful builds are:
--> centos-8: 'virtualbox' provider box: centos-8-kernel-5-x86_64-Minimal.box
В каталоге packer появился файл сentos-8-kernel-5-x86_64-Minimal.box
2.6 Для проверки  импортировал vagrant box в Vagrant:
alex@Ubuntu-Mak:~/packer$ vagrant box add centos8-kernel5 centos-8-kernel-5-x86_64-Minimal.box
2.7 Проверил список образов:
alex@Ubuntu-Mak:~/packer$ vagrant box list
centos/7        (virtualbox, 2004.01)
centos8-kernel5 (virtualbox, 0)
2.8 Создал vagrant файл:
alex@Ubuntu-Mak:~/packer$ vagrant init centos8-kernel5
2.9 Выполнил включение вм, проверку подключения и выключение:
alex@Ubuntu-Mak:~/packer$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'centos8-kernel5'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: packer_default_1683202090784_78477
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: vagrant
    default: SSH auth method: private key
    default:
    default: Vagrant insecure key detected. Vagrant will automatically replace
    default: this with a newly generated keypair for better security.
    default:
    default: Inserting generated public key within guest...
    default: Removing insecure key from the guest if it's present...
    default: Key inserted! Disconnecting and reconnecting using new SSH key...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
    default: No guest additions were detected on the base box for this VM! Guest
    default: additions are required for forwarded ports, shared folders, host only
    default: networking, and more. If SSH fails on this machine, please install
    default: the guest additions and repackage the box to continue.
    default:
    default: This is not an error message; everything may continue to work properly,
    default: in which case you may ignore this message.
==> default: Mounting shared folders...
    default: /vagrant => /home/alex/packer

alex@Ubuntu-Mak:~/packer$ vagrant ssh
Last login: Wed May  3 13:33:02 2023
[vagrant@otus-c8 ~]$ uname -r
6.3.1-1.el8.elrepo.x86_64
[vagrant@otus-c8 ~]$ exit
logout
alex@Ubuntu-Mak:~/packer$ vagrant destroy --force
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives...

3) Загрузить Vagrant box в Vagrant Cloud

3.1 Находясь в каталоге packer залогинился в vagrant cloud:
alex@Ubuntu-Mak:~/packer$ vagrant cloud auth login --token xlG29XRqedzKeA.atlasv1.BlQWmeNCMQyobIyzdVTwzJK7ZShKcczLBnz2WgwaAVEhbA7WYQtSMlKXLkPnWOPV57
The token was successfully saved.
You are already logged in.

3.2 Опубликовал образ:
alex@Ubuntu-Mak:~/packer$ vagrant cloud publish --release mak_aleksei/centos8-kernel5 1.0 virtualbox centos-8-kernel-5-x86_64-Minimal.box
You are about to publish a box on Vagrant Cloud with the following options:
mak_aleksei/centos8-kernel5:   (v1.0) for provider 'virtualbox'
Automatic Release:     true
Do you wish to continue? [y/N]y
Saving box information...
Uploading provider with file /home/alex/packer/centos-8-kernel-5-x86_64-Minimal.box
Releasing box...
Complete! Published mak_aleksei/centos8-kernel5
Box:              mak_aleksei/centos8-kernel5
Description:
Private:          yes
Created:          2023-05-04T10:11:17.224Z
Updated:          2023-05-04T10:11:17.224Z
Current Version:  N/A
Versions:         1.0
Downloads:        0

