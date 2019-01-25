#!/bin/bash
NODE_DIR=/home/plat/web4node
NODE_BAK_DIR=/data/bakup/node
NODE=public
DATE=`date +"%Y%m%d"`
mkdir -p $NODE_BAK_DIR
cd $NODE_DIR
tar zcvf $NODE_BAK_DIR/$NODE.$DATE.tar.gz $NODE
find $NODE_BAK_DIR -mtime +15 -type f -exec rm -rf {} \;
exit