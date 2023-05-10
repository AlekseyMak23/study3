Дисковая подсистема

Добавил в Vagrantfile следующие блоки для 2 дисков (решил собрать Raid 10) -
:sata5 => {
:dfile => './sata5.vdi', # Путь, по которому будет создан файл диска
:size => 250, # Размер диска в мегабайтах
:port => 5 # Номер порта, на который будет зацеплен диск
},
:sata6 => {
:dfile => './sata6.vdi', # Путь, по которому будет создан файл диска
:size => 250, # Размер диска в мегабайтах
:port => 6 # Номер порта, на который будет зацеплен диск
},


Включил вм, подключился по ssh -
alex@Ubuntu-Mak:~$ vagrant up
alex@Ubuntu-Mak:~$ vagrant ssh

Проверил наличие блочных устройств -
[vagrant@otuslinux ~]$ sudo lshw -short | grep disk
/0/100/1.1/0.0.0    /dev/sda  disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb  disk        262MB VBOX HARDDISK
/0/100/d/1          /dev/sdc  disk        262MB VBOX HARDDISK
/0/100/d/2          /dev/sdd  disk        262MB VBOX HARDDISK
/0/100/d/3          /dev/sde  disk        262MB VBOX HARDDISK
/0/100/d/4          /dev/sdf  disk        262MB VBOX HARDDISK
/0/100/d/5          /dev/sdg  disk        262MB VBOX HARDDISK

Создал Raid10 -
[vagrant@otuslinux ~]$ sudo mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd{b,c,d,e,f,g}
mdadm: layout defaults to n2
mdadm: layout defaults to n2
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.

Проверил состояние Raid после сборки -
[vagrant@otuslinux ~]$ cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sdg[5] sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]
unused devices: <none>

[vagrant@otuslinux ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri May  5 07:13:43 2023
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Fri May  5 07:13:47 2023
             State : clean
    Active Devices : 6
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : de6138de:b1f81be2:d076b0e4:8c8ed426
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       3       8       64        3      active sync set-B   /dev/sde
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg

Проверил информацию о Raid -
[vagrant@otuslinux ~]$ sudo mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid10 num-devices=6 metadata=1.2 name=otuslinux:0 UUID=de6138de:b1f81be2:d076b0e4:8c8ed426
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf,/dev/sdg

Создал конфигурационный файл mdadm.conf - 
#sudo mkdir /etc/mdadm
#sudo cd /etc/mdadm
#sudo touch mdadm.conf
#sudo chmod 777 mdadm.conf
#sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
Проверка информации в файле -
[vagrant@otuslinux mdadm]$ cat mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=6 metadata=1.2 name=otuslinux:0 UUID=de6138de:b1f81be2:d076b0e4:8c8ed426

Сломал Raid -
[vagrant@otuslinux mdadm]$ sudo mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
Проверяю -
[vagrant@otuslinux mdadm]$ cat /proc/mdstat
Personalities : [raid10]
md0 : active raid10 sdg[5] sdf[4] sde[3](F) sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 512K chunks 2 near-copies [6/5] [UUU_UU]

unused devices: <none>

[vagrant@otuslinux mdadm]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri May  5 07:13:43 2023
        Raid Level : raid10
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Fri May  5 07:28:53 2023
             State : clean, degraded
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 1
     Spare Devices : 0

            Layout : near=2
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : de6138de:b1f81be2:d076b0e4:8c8ed426
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync set-A   /dev/sdb
       1       8       32        1      active sync set-B   /dev/sdc
       2       8       48        2      active sync set-A   /dev/sdd
       -       0        0        3      removed
       4       8       80        4      active sync set-A   /dev/sdf
       5       8       96        5      active sync set-B   /dev/sdg

       3       8       64        -      faulty   /dev/sde

Удаляю “сломанный” диск из массива -
[vagrant@otuslinux mdadm]$ sudo mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0

Добавляю "новый" диск в массив -
[vagrant@otuslinux mdadm]$ sudo mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde

Создаю GPT раздел, пять партиций и монитирую их на диск -
[vagrant@otuslinux mdadm]$ sudo parted -s /dev/md0 mklabel gpt

[vagrant@otuslinux mdadm]$ sudo parted /dev/md0 mkpart primary ext4 0% 15%
[vagrant@otuslinux mdadm]$ sudo parted /dev/md0 mkpart primary ext4 15% 30%
[vagrant@otuslinux mdadm]$ sudo parted /dev/md0 mkpart primary ext4 30% 45%
[vagrant@otuslinux mdadm]$ sudo parted /dev/md0 mkpart primary ext4 45% 60%
[vagrant@otuslinux mdadm]$ sudo parted /dev/md0 mkpart primary ext4 60% 75%
[vagrant@otuslinux mdadm]$ sudo parted /dev/md0 mkpart primary ext4 75% 100%

Создаю на партициях ФС -
[vagrant@otuslinux mdadm]$ for i in $(seq 1 6); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
30000 inodes, 119808 blocks
5990 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33685504
15 block groups
8192 blocks per group, 8192 fragments per group
2000 inodes per group
Superblock backups stored on blocks:
        8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

Монтирую по каталогам -
[vagrant@otuslinux mdadm]$ sudo mkdir -p /raid/part{1,2,3,4,5,6}
[vagrant@otuslinux mdadm]$ cd /raid/
[vagrant@otuslinux raid]$ ll
total 0
drwxr-xr-x. 2 root root 6 May  5 09:02 part1
drwxr-xr-x. 2 root root 6 May  5 09:02 part2
drwxr-xr-x. 2 root root 6 May  5 09:02 part3
drwxr-xr-x. 2 root root 6 May  5 09:02 part4
drwxr-xr-x. 2 root root 6 May  5 09:02 part5
drwxr-xr-x. 2 root root 6 May  5 09:02 part6

Далее собрал команды в командный файл make_raid.sh, проверил после удаления и включения с нуля виртуальной машины.

Затем добавил их в Vagrantfile, в раздел box.vm.provision "shell", inline: <<-SHELL.

Туда же скрипт, который сразу собирает систему с подключенным рейдом и смонтированными разделами -

#echo "#NEW DEVICE" >> /etc/fstab
#for i in $(seq 1 6); do echo `sudo blkid /dev/md0p$i | awk '{print $2}'` /u0$i ext4 defaults 0 0 >> /etc/fstab; done

