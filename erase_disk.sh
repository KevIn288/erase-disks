#!/bin/bash

## get all disk but the system and start scrub, that we suppose it is sda
for _disks in $(fdisk -l | grep -i 'Disk /dev' | grep -v sda | awk '{print $2}' | tr ":" " " | sort); do scrub --pattern bsi --force --no-signature --no-hwrand $_disks >> /dev/null 2>&1 & done; wait
#wait
## prepare the disks for encryption with badblocks command
for _disks in $(fdisk -l | grep -i 'Disk /dev' | grep -v sda | awk '{print $2}' | tr ":" " " | sort); do badblocks -c 10240 -s -w -t random -v $_disks >> /dev/null 2>&1 & done;
#wait
## create partition for each drives
for _disks in $(fdisk -l | grep -i 'Disk /dev' | grep -v sda | awk '{print $2}' | tr ":" " " | sort); do echo -e "o\nn\np\n1\n\n\nw" | fdisk $_disks; done
## create keyfiles for each drive to delete
for _keys in $(fdisk -l | grep -i Linux | grep -v sda | grep -v loop | awk '{print $1}' | tr ":" " " | sort | cut -c 6-9); do dd if=/dev/urandom of=/root/key_files_temp/key_file_$_keys bs=4096 count=16 >> /dev/null 2>&1; done;
## encrypted all drives
for _partitions in $(fdisk -l | grep -i Linux | grep -v sda | grep -v loop |  awk '{ print $1}' | tr ":" " " | sort | cut -c 6-9); do cryptsetup luksFormat -q --hash sha512 --use-urandom --verify-passphrase /dev/$_partitions --key-file=/root/key_files_temp/key_file_$_partitions; done
## open encrypted hard drive
for _partitions in $(fdisk -l | grep -i Linux | grep -v sda | grep -v loop |  awk '{ print $1}' | tr ":" " " | sort | cut -c 6-9); do cryptsetup luksOpen /dev/$_partitions crypt_$_partitions --key-file=/root/key_files_temp/key_file_$_partitions; done
## make file system on each volume
for _mappers in $(ls /dev/mapper/crypt_sd*); do mkfs.ext4 $_mappers; done
## mount all partition
for _partitions in $(fdisk -l | grep -i Linux | grep -v sda | grep -v loop |  awk '{ print $1}' | tr ":" " " | sort | cut -c 6-9); do mount /dev/mapper/crypt_$_partitions /mnt/delete/$_partitions; done
## Download some junks to fills all the drives
for _path in $(df -h | grep mnt | grep -v cdrom | awk '{print $6}'); do wget -i /root/urls.txt -P $_path >> /dev/null 2>&1 & done

## TODO


