Введение в работу с LVM

Проверка устройств для использования:
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
[vagrant@lvm ~]$ sudo lvmdiskscan
  /dev/VolGroup00/LogVol00 [     <37.47 GiB]
  /dev/VolGroup00/LogVol01 [       1.50 GiB]
  /dev/sda2                [       1.00 GiB]
  /dev/sda3                [     <39.00 GiB] LVM physical volume
  /dev/sdb                 [      10.00 GiB]
  /dev/sdc                 [       2.00 GiB]
  /dev/sdd                 [       1.00 GiB]
  /dev/sde                 [       1.00 GiB]
  4 disks
  3 partitions
  0 LVM physical volume whole disks
  1 LVM physical volume

Создание PV:
[vagrant@lvm ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
Создание VG:
[vagrant@lvm ~]$ sudo vgcreate otus /dev/sdb
  Volume group "otus" successfully created
Создание LV:
[vagrant@lvm ~]$ sudo lvcreate -l+80%FREE -n test otus
  Logical volume "test" created.

Просмотр информации о созданной Volume Group:
[vagrant@lvm ~]$ sudo vgdisplay otus
  --- Volume group ---
  VG Name               otus
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       2047 / <8.00 GiB
  Free  PE / Size       512 / 2.00 GiB
  VG UUID               Ujfwgp-FZyD-YMFB-wgRo-like-Quz5-Kxla3h

Просмотр информации о отм, какие диски входят в VG:
[vagrant@lvm ~]$ sudo vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/sdb

Просмотр информации о LV:
[vagrant@lvm ~]$ sudo lvdisplay /dev/otus/test
  --- Logical volume ---
  LV Path                /dev/otus/test
  LV Name                test
  VG Name                otus
  LV UUID                uuCpOK-XM0j-EDyt-FE6M-Q3fF-tbbL-Ts2ayO
  LV Write Access        read/write
  LV Creation host, time lvm, 2023-05-17 10:32:17 +0000
  LV Status              available
  # open                 0
  LV Size                <8.00 GiB
  Current LE             2047
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:2

Просмотр информации о LV и VG в сжатом виде:
[vagrant@lvm ~]$ sudo vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0
  otus         1   1   0 wz--n- <10.00g 2.00g
[vagrant@lvm ~]$ sudo lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  test     otus       -wi-a-----  <8.00g

Создадим еще один LV:
[vagrant@lvm ~]$ sudo lvcreate -L100M -n small otus
  Logical volume "small" created.
[vagrant@lvm ~]$ sudo lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  small    otus       -wi-a----- 100.00m
  test     otus       -wi-a-----  <8.00g

Создадим на LV файловую систему:
[vagrant@lvm ~]$ sudo mkfs.ext4 /dev/otus/test
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
524288 inodes, 2096128 blocks
104806 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2147483648
64 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done

Смонтируем LV в каталог /data:
[vagrant@lvm ~]$ sudo mkdir /data
[vagrant@lvm ~]$ sudo mount /dev/otus/test /data/
[vagrant@lvm ~]$ sudo mount | grep /data
/dev/mapper/otus-test on /data type ext4 (rw,relatime,seclabel,data=ordered)


Расширение LVM

Создадим PV:
[vagrant@lvm ~]$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.

Расширим VG и добавим диск:
[vagrant@lvm ~]$ sudo vgextend otus /dev/sdc
  Volume group "otus" successfully extended

Проверим наличие диска в VG и увеличение места:
[vagrant@lvm ~]$ sudo vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/sdb
  PV Name               /dev/sdc
[vagrant@lvm ~]$ sudo vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g     0
  otus         2   2   0 wz--n-  11.99g <3.90g

Сымитируем занятое место:
[vagrant@lvm ~]$ sudo dd if=/dev/zero of=/data/test.log bs=1M count=8000 status=progress
7732199424 bytes (7.7 GB) copied, 17.588295 s, 440 MB/s
dd: error writing ‘/data/test.log’: No space left on device
7880+0 records in
7879+0 records out
8262189056 bytes (8.3 GB) copied, 18.5146 s, 446 MB/s

Проверка дсикового пространства:
[vagrant@lvm ~]$ sudo df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  7.8G  7.8G     0 100% /data

Увеличим LV за счет части свободного места:
[vagrant@lvm ~]$ sudo lvextend -l+80%FREE /dev/otus/test
  Size of logical volume otus/test changed from <8.00 GiB (2047 extents) to <11.12 GiB (2846 extents).
  Logical volume otus/test successfully resized.

Проверка дискового пространства:
[vagrant@lvm ~]$ sudo df -Th /data
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  7.8G  7.8G     0 100% /data

Произведем изменение размера файловой системы:
[vagrant@lvm ~]$ sudo resize2fs /dev/otus/test
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/otus/test is mounted on /data; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 2
The filesystem on /dev/otus/test is now 2914304 blocks long.

Проверка дискового пространства:
[vagrant@lvm ~]$ sudo df -Th /data
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4   11G  7.8G  2.6G  76% /data


Уменьшение LVM

Отмонтируем файловую систему, проверим на ошибки и уменьшим размер -
[vagrant@lvm ~]$ sudo umount /data/
[vagrant@lvm ~]$ sudo e2fsck -fy /dev/otus/test
e2fsck 1.42.9 (28-Dec-2013)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/otus/test: 12/729088 files (0.0% non-contiguous), 2105907/2914304 blocks
[vagrant@lvm ~]$ sudo resize2fs /dev/otus/test 10G
resize2fs 1.42.9 (28-Dec-2013)
Resizing the filesystem on /dev/otus/test to 2621440 (4k) blocks.
The filesystem on /dev/otus/test is now 2621440 blocks long.

[vagrant@lvm ~]$ sudo lvreduce /dev/otus/test -L 10G
  WARNING: Reducing active logical volume to 10.00 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce otus/test? [y/n]: y
  Size of logical volume otus/test changed from <11.12 GiB (2846 extents) to 10.00 GiB (2560 extents).
  Logical volume otus/test successfully resized.


Подмонтируем файловую систему:
[vagrant@lvm ~]$ sudo mount /dev/otus/test /data/

Проверка дискового пространства:
[vagrant@lvm ~]$ sudo df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  9.8G  7.8G  1.6G  84% /data

Просмотр информации о LV:
[vagrant@lvm ~]$ sudo lvs /dev/otus/test
  LV   VG   Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-ao---- 10.00g


LVM Snapshot

Создадим снэпшот:
[vagrant@lvm ~]$ sudo lvcreate -L 500M -s -n test-snap /dev/otus/test
  Logical volume "test-snap" created.

Просмотр информации о VG:
[vagrant@lvm ~]$ sudo vgs -o +lv_size,lv_name | grep test
  otus         2   3   1 wz--n-  11.99g <1.41g  10.00g test
  otus         2   3   1 wz--n-  11.99g <1.41g 500.00m test-snap

Проверка устройств для использования:
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
├─otus-small            253:3    0  100M  0 lvm
└─otus-test-real        253:4    0   10G  0 lvm
  ├─otus-test           253:2    0   10G  0 lvm  /data
  └─otus-test--snap     253:6    0   10G  0 lvm
sdc                       8:32   0    2G  0 disk
├─otus-test-real        253:4    0   10G  0 lvm
│ ├─otus-test           253:2    0   10G  0 lvm  /data
│ └─otus-test--snap     253:6    0   10G  0 lvm
└─otus-test--snap-cow   253:5    0  500M  0 lvm
  └─otus-test--snap     253:6    0   10G  0 lvm
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk

Создадим папку и смонтируем в нее снэпшот:
[vagrant@lvm ~]$ sudo mkdir /data-snap
[vagrant@lvm ~]$ sudo mount /dev/otus/test-snap /data-snap/
[vagrant@lvm ~]$ ll /data-snap/
total 8068564
drwx------. 2 root root      16384 May 17 10:35 lost+found
-rw-r--r--. 1 root root 8262189056 May 17 10:39 test.log

Отмонтируем папку со снэпшотом:
[vagrant@lvm ~]$ sudo umount /data-snap

Удалим файл:
[vagrant@lvm ~]$ sudo rm /data/test.log
[vagrant@lvm ~]$ ll /data
total 16
drwx------. 2 root root 16384 May 17 10:35 lost+found

Отмонтируем папку с данными
[vagrant@lvm ~]$ sudo umount /data

Откатимся на снэпшот:
[vagrant@lvm ~]$ sudo lvconvert --merge /dev/otus/test-snap
  Merging of volume otus/test-snap started.
  otus/test: Merged: 100.00%

Смонтируем папку и проверим наличие данных:
[vagrant@lvm ~]$ sudo mount /dev/otus/test /data
[vagrant@lvm ~]$ ll /data
total 8068564
drwx------. 2 root root      16384 May 17 10:35 lost+found
-rw-r--r--. 1 root root 8262189056 May 17 10:39 test.log


Работа с LVM

[vagrant@lvm ~]$ sudo pvcreate /dev/sd{d,e}
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.
[vagrant@lvm ~]$ sudo vgcreate vg0 /dev/sd{d,e}
  Volume group "vg0" successfully created
[vagrant@lvm ~]$ sudo lvcreate -l+80%FREE -m1 -n mirror vg0
  Logical volume "mirror" created.
[vagrant@lvm ~]$ sudo lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  small    otus       -wi-a----- 100.00m
  test     otus       -wi-ao----  10.00g
  mirror   vg0        rwi-a-r--- 816.00m                                    100.00


Далее выполняю домашнее задание с логированием ввода-вывода команд утилитой script и выводом лога putty:
1. Уменьшить том до 8Gb - script1.log, script2.log
2. Выделить том под /var в зеркало - script3.log
3. Выделить том под /home + сделать том для снэпшотов (работа со снэпшотами - сгенерированы файлы в /home, снят снэпшот, удалена часть файлов, восстановлены данные из снэпшота) - putty.log
4. Прописано монтирование в /etc/fstab


