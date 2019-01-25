#/bin/bash
DB_DIR=/home/plat/redis
DB_BAK_DIR=/data/bakup/db/redis
DATE=`date +"%Y%m%d"`
mkdir -p $DB_BAK_DIR
cd $DB_BAK_DIR
cp $DB_DIR/dump.rdb $DB_BAK_DIR/dump.rdb.${DATE}
find $DB_BAK_DIR -mtime +15 -type f -exec rm -rf {} \;
exit