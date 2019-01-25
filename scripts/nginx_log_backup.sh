#!/bin/bash
LOG_DIR=/home/plat/nginx/logs
LOG_BAK_DIR=/data/bakup/log/nginx
LOG=access.log
DATE=`date +"%Y%m%d"`
mkdir -p $LOG_BAK_DIR
cd $LOG_DIR
tar zcvf $LOG_BAK_DIR/$LOG.$DATE.tar.gz $LOG
> $LOG_DIR/$LOG
find $LOG_BAK_DIR -mtime +30 -type f -exec rm -rf {} \;
exit