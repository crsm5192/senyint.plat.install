#/bin/bash
DB_BAK_DIR=/data/bakup/db/mysql
DATE=`date +"%Y%m%d"`
mkdir -p $DB_BAK_DIR
cd $DB_BAK_DIR
mysqldump --all-databases > all-db-$DATE.sql
find $DB_BAK_DIR -mtime +15 -type f -exec rm -rf {} \;
exit