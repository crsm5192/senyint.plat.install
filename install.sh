#!/bin/bash
#var
. ./var_list
#fun
. ${INSTALL_DIR}/include/general.sh
#info page
clear
root_user_check
printf "
\033[31m请仔细阅读以下内容:\033[0m                                            
\033[31m软件包版本：\033[0m                                         
`ls ${INSTALL_DIR}/source|grep nginx-1|awk -F ".tar" '{print $1}'`               |        `ls ${INSTALL_DIR}/source|grep mysql|awk -F ".tar" '{print $1}'`
`ls ${INSTALL_DIR}/source|grep tomcat|awk -F ".tar" '{print $1}'`       |        `ls ${INSTALL_DIR}/source|grep redis|awk -F ".tar" '{print $1}'`
`ls ${INSTALL_DIR}/source|grep zookeeper|awk -F ".tar" '{print $1}'`           |        `ls ${INSTALL_DIR}/source|grep kafka|awk -F ".taz" '{print $1}'`    
`ls ${INSTALL_DIR}/source|grep node-v|awk -F ".tar" '{print $1}'`     |        `ls ${INSTALL_DIR}/source|grep ds-|awk -F ".tar" '{print $1}'`    
`ls ${INSTALL_DIR}/source|grep samba|awk -F ".tar" '{print $1}'`                |        `ls ${INSTALL_DIR}/source|grep squid|awk -F ".tar" '{print $1}'`
\033[31m支持包版本:\033[0m
`ls ${INSTALL_DIR}/source|grep jdk|awk -F ".tar" '{print $1}'`        |        `ls ${INSTALL_DIR}/source|grep pcre|awk -F ".tar" '{print $1}'`                                     
`ls ${INSTALL_DIR}/source|grep zlib|awk -F ".tar" '{print $1}'`                |        `ls ${INSTALL_DIR}/source|grep jemalloc|awk -F ".tar" '{print $1}'`                                     
`ls ${INSTALL_DIR}/source|grep yum|awk -F ".tar" '{print $1}'`               |        `ls ${INSTALL_DIR}/source|grep openssl|awk -F ".tar" '{print $1}'`                                     
`ls ${INSTALL_DIR}/source|grep ngx_devel_kit|awk -F ".tar" '{print $1}'`     |        `ls ${INSTALL_DIR}/source|grep LuaJIT|awk -F ".tar" '{print $1}'`
`ls ${INSTALL_DIR}/source|grep lua-nginx-module|awk -F ".tar" '{print $1}'`
\033[31m监控软件版本:\033[0m
`ls ${INSTALL_DIR}/source|grep zabbix|awk -F ".tar" '{print $1}'`              |        `ls ${INSTALL_DIR}/source|grep filebeat|awk -F ".tar" '{print $1}'`                                     
\033[31m安装信息\033[0m(install.sh内修改):
本机IP:\033[31m$HOST_IP\033[0m|Elastic日志分析服务器:\033[31m$ELK_IP\033[0m
Ansible运维服务器:\033[31m$ANS_IP\033[0m|Zabbix监控服务器地址:\033[31m$ZBX_IP\033[0m
平台用户:\033[31m$PLAT_USER\033[0m|平台安装目录:\033[31m$PLAT_HOME\033[0m
共享存储挂载目的IP:\033[31m$SMB_IP\033[0m|共享存储目录:\033[31m$SMB_DIR\033[0m
监控软件安装目录:\033[31m$MON_HOME\033[0m|备份目录:\033[31m$BAK_HOME\033[0m
\033[31m端口信息\033[0m(相应配置文件内修改):
web端口:\033[31m${NGX_PORT}\033[0m|mysql端口:\033[31m${MYSQL_PORT}\033[0m|redis端口:\033[31m${REDIS_PORT}\033[0m
zookeeper端口:\033[31m${ZOO_PORT}\033[0m|jmx端口:\033[31m${ZOO_JMX_PORT}\033[0m|zookeeper选举端口:\033[31m${ZOO_REG_PORT}\033[0m
kafka端口:\033[31m${KAFKA_PORT}\033[0m|jmx端口:\033[31m${KAFKA_JMX_PORT}\033[0m
tomcat端口:\033[31m${TOM_PORT}\033[0m|jmx端口:\033[31m${TOM_JMX_PORT}\033[0m
zabbix端口:\033[31m${ZBX_AGENT_PORT}\033[0m|logstash日志分析端口:\033[31m${LOGS_PORT}\033[0m
samba共享存储端口:\033[31m${SMB_PORT}\033[0m|squid代理端口:\033[31m${SQ_PORT}\033[0m
\033[31m其他信息\033[0m:
当前版本仅centos7适用
---------------------------------------------
"
#read hostname
echo -n '请输入当前服务器名(hostname,仅首次执行该脚本输入,之后可按任意键跳过):'
read CHAR
export HOST_NAME=$CHAR
cat ${INSTALL_DIR}/README.md
install_package
