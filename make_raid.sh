#!/bin/bash
sudo mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd{b,c,d,e,f,g}
sudo mkdir /etc/mdadm
sudo cd /etc/mdadm
sudo touch mdadm.conf
sudo chmod 777 mdadm.conf
sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
sudo parted -s /dev/md0 mklabel gpt
sudo parted /dev/md0 mkpart primary ext4 0% 15%
sudo parted /dev/md0 mkpart primary ext4 15% 30%
sudo parted /dev/md0 mkpart primary ext4 30% 45%
sudo parted /dev/md0 mkpart primary ext4 45% 60%
sudo parted /dev/md0 mkpart primary ext4 60% 75%
sudo parted /dev/md0 mkpart primary ext4 75% 100%
for i in $(seq 1 6); do sudo mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4,5,6}
for i in $(seq 1 6); do mount /dev/md0p$i /raid/part$i; done
echo "#NEW DEVICE" >> /etc/fstab
for i in $(seq 1 6); do echo `sudo blkid /dev/md0p$i | awk '{print $2}'` /u0$i ext4 defaults 0 0 >> /etc/fstab; done
