#!/bin/bash
set -eo pipefail

# VARIABLES
SWAP_PATH=/swapfile
SWAP_SIZE=2G

while getopts :p:s: flag
do
    case "${flag}" in
        p) SWAP_PATH=${OPTARG};;
        s) SWAP_SIZE=${OPTARG};;
    esac
done

printf "\nCreating ${SWAP_PATH} file with sixe of ${SWAP_SIZE}\n\n"
fallocate -l ${SWAP_SIZE} ${SWAP_PATH}

printf "\n\n\nSetting 0600 permission to ${SWAP_PATH}\n\n"
chmod 600 ${SWAP_PATH}

printf "\n\n\nFormating ${SWAP_PATH} as swap.\n\n"
mkswap ${SWAP_PATH}

printf "\n\n\nMaking a backup of fstab.\n\n"
cp /etc/fstab /etc/fstab.bak

printf "\n\n\nEnabling ${SWAP_PATH} as swap.\n\n"
swapon ${SWAP_PATH}
echo "${SWAP_PATH} none swap sw 0 0" >> /etc/fstab

printf "\n\n\nSetting vm.swappiness=10.\n\n"
sysctl vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf

printf "\n\n\nSetting vm.vfs_cache_pressure=50.\n\n"
sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf

printf "\n\n\nDone! Swap status:\n\n"
free -h
printf "\n\n\n"
