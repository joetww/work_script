#!/bin/sh

RC_FILE="${HOME}/.mysql_backuprc"
if [ -f "${RC_FILE}" ]; then
        source ${RC_FILE}
else
        echo "Check Config File: ${RC_FILE}"
        cat << EOD
# 'db_user' is mysql username
# 'db_passwd' is mysql password
# 'db_host' is mysql host
# 'backup_dir' is the directory for story your backup file
# 'keep_backup' is used to configure the amount to store backup data
EOD
        exit 2
fi

if [ -z ${db_user+x} ]; then echo "db_user is unset";exit 4; fi
if [ -z ${db_passwd+x} ]; then echo "db_passwd is unset";exit 4; fi
if [ -z ${db_host+x} ]; then echo "db_host is unset";exit 4; fi
if [ -z ${backup_dir+x} ]; then echo "backup_dir is unset";exit 4; fi
if [ -z ${keep_backup+x} ]; then echo "keep_backup is unset"; exit 4; fi

# date format for backup file (dd-mm-yyyy)
time="$(date +"%d-%m-%Y")"

# mysql, mysqldump and some other bin's path
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
MKDIR="$(which mkdir)"
RM="$(which rm)"
MV="$(which mv)"
GZIP="$(which gzip)"

# check the directory for store backup is writeable
test ! -w $backup_dir && echo "Error: $backup_dir is un-writeable." && exit 0

# the directory for story the newest backup
test ! -d "$backup_dir/backup.0/" && $MKDIR "$backup_dir/backup.0/"

# get all databases
all_db="$($MYSQL -u $db_user -h $db_host -p$db_passwd -Bse 'show databases' | grep -v -P '^information_schema$|^mysql$')"

for db in $all_db
do
        $MYSQLDUMP -u $db_user -h $db_host -p$db_passwd $db | $GZIP -9 > "$backup_dir/backup.0/$time.$db.gz"
done

# delete the oldest backup
test -d "$backup_dir/backup.${keep_backup}/" && $RM -rf "$backup_dir/backup.${keep_backup}"

# rotate backup directory
for int in $(seq `expr ${keep_backup} - 1` -1 0 | xargs)
do
        if(test -d "$backup_dir"/backup."$int")
        then
                next_int=`expr $int + 1`
                $MV "$backup_dir"/backup."$int" "$backup_dir"/backup."$next_int"
        fi
done

exit 0;
################################################
###### 補充 設定檔 ${HOME}/.mysql_backuprc #####
################################################
db_user="xxxxxxxx"
db_passwd="xxxxxxxx"
db_host="10.0.0.1"
backup_dir="/cygdrive/d/mysql_backup"
keep_backup=7
