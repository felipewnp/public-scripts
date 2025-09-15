#!/bin/bash

set -euo pipefail

#######################################################################
##############################  CHANGE:  ##############################
#######################################################################
admin_user_host_from="admin"
admin_pass_host_from="" # if empty, will prompt
admin_user_host_to="admin"
admin_pass_host_to="" # if empty, will prompt
db_name="api-name"
host_from="host-a"
host_to="host-b"
#
create_user="false" # true/false
db_user="api-name"
db_pass="my-secret-password"
#######################################################################
#######################################################################
#######################################################################
###
##
#

if [ ${admin_pass_host_from} == "" ]; then
	read -s -p "Enter host_from password: " admin_pass_host_from
fi

if [ ${admin_pass_host_to} == "" ]; then
	read -s -p "Enter host_to password: " admin_pass_host_to
fi

date=$(date +"%Y%m%d-%H%M%S")
file=${db_name}-${date}.sql

printf "\n\n\nConfirm the input values:\n\nHOST_FROM: ${host_from}\nHOST_TO: ${host_to}\nDB_NAME: ${db_name}\nDB_USER: ${db_user}\nDB_PASS: ${db_pass}\n\n"
read -p "Press enter to continue or ctrl+c to exit"
printf "\nContinuing..\n"

printf "\n\n\nDumping ${db_name} From ${host_from} To ${file}\n"
/usr/bin/mysqldump -u ${admin_user_host_from} --password=${admin_pass_host_from} --skip-lock-tables --routines --add-drop-table --disable-keys --extended-insert --set-gtid-purged=OFF --host=${host_from} --port=3306 ${db_name} >${file} || exit 1
# Alternative version with net_buffer_length set to 16384 (NOT TESTED YET!)
# https://dba.stackexchange.com/questions/183241/mysqldump-not-exporting-all-rows-or-mysql-not-importing
# /usr/bin/mysqldump --net_buffer_length=16384 -u ${admin_user_host_from} --password=${admin_pass_host_from} --skip-lock-tables --routines --add-drop-table --disable-keys --extended-insert --set-gtid-purged=OFF --host=${host_from} --port=3306 ${db_name} >${file} || exit 1

printf "\n\n\nInitializing ${db_name} inside ${host_to}\n"
/usr/bin/mysql -u ${admin_user_host_to} --password=${admin_pass_host_to} --host=${host_to} --port=3306 --execute="CREATE DATABASE IF NOT EXISTS \`${db_name}\`;" || exit 1

printf "\n\n\nRestoring ${db_name} From ${file} To ${host_to}\n"
/usr/bin/mysql -u ${admin_user_host_to} --password=${admin_pass_host_to} --host=${host_to} --port=3306 ${db_name} <${file} || exit 1

if [ ${create_user} == "true" ]; then
	printf "\n\n\nCreating user ${db_user} in ${host_to}...\n"
	/usr/bin/mysql -u ${admin_user_host_to} --password=${admin_pass_host_to} --host=${host_to} --port=3306 --execute="CREATE USER IF NOT EXISTS \`${db_user}\`@'%' IDENTIFIED BY '${db_pass}';" || exit 1

	printf "\n\n\nGranting user ${db_user} permissions in ${db_name}...\n"
	/usr/bin/mysql -u ${admin_user_host_to} --password=${admin_pass_host_to} --host=${host_to} --port=3306 --execute="GRANT ALTER,CREATE,CREATE VIEW,DELETE,DROP,INDEX,INSERT,REFERENCES,SELECT,SHOW VIEW,TRIGGER,UPDATE,ALTER ROUTINE,CREATE ROUTINE,CREATE TEMPORARY TABLES,EXECUTE,LOCK TABLES ON \`${db_name}\`.* TO \`${db_user}\`@'%';" || exit 1
fi

secs=$SECONDS
hrs=$((secs / 3600))
mins=$(((secs - hrs * 3600) / 60))
secs=$((secs - hrs * 3600 - mins * 60))

printf "\n\n\n" && printf 'Done in: %02d:%02d:%02d\n' $hrs $mins $secs
