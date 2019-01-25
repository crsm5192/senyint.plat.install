#!/bin/bash

#start
echo "`date +%F\ %T` 开始安装filebeat日志收集端"

#elastic_user_check
id ${ELA_USER} &>/dev/null
if [ $? = 1 ];then
	groupadd -g 9200 ${ELA_USER} 1>/dev/null
	useradd -g ${ELA_USER} -u 9200 ${ELA_USER} -s /sbin/nologin 1>/dev/null
fi

#filebeat_install
mkdir -p ${MON_HOME}/elastic
FLB_SOURCE=`ls ${INSTALL_DIR}/source | grep filebeat`
tar zxvf ${INSTALL_DIR}/source/${FLB_SOURCE} -C ${MON_HOME}/elastic 1>/dev/null
FLB_PATH=`ls ${MON_HOME}/elastic | grep filebeat`
FLB_PATH=${MON_HOME}/elastic/${FLB_PATH}

#filebeat_install_conf
mv ${FLB_PATH}/filebeat.yml ${FLB_PATH}/filebeat.ymlbak
cat > ${FLB_PATH}/filebeat.yml<<conf_head
filebeat.prospectors:
conf_head

#filebeat_install_conf_nginx
if [ ! -d "${PLAT_HOME}/nginx" ];then
	echo "`date +%F\ %T` 未安装nginx,不配置nginx日志收集"
else
	chmod 755 ${PLAT_HOME}/nginx/logs/access.log
	chmod 755 ${PLAT_HOME}/nginx/logs/error.log
	cat >> ${FLB_PATH}/filebeat.yml<<conf_nginx
#nginx_access
- type: log
  paths:
    - ${PLAT_HOME}/nginx/logs/access.log
  encoding: utf-8
  fields:
    logtype: nginx_access_log
    group: ${PLAT_GROUP}
    server: ${PLAT_SERVER}
    ipaddr: ${HOST_IP}
  fields_under_root: true
#nginx_error 
- type: log
  paths:
    - ${PLAT_HOME}/nginx/logs/error.log
  encoding: utf-8
  fields:
    logtype: nginx_error_log
    group: ${PLAT_GROUP}
    server: ${PLAT_SERVER}
    ipaddr: ${HOST_IP}
  fields_under_root: true	
conf_nginx
fi

#filebeat_install_conf_TOMCAT
if [ ! -d "${PLAT_HOME}/dscore" ];then
	echo "`date +%F\ %T` 未安装dscore,不配置tomcat日志收集"
else
	chmod 755 ${PLAT_HOME}/ds-log/ds.log
	cat >> ${FLB_PATH}/filebeat.yml<<conf_tomcat
#tomcat 
- type: log
  paths:
    - ${PLAT_HOME}/ds-log/ds.log
  encoding: utf-8
  multiline:
    pattern: '^[0-2][0-9]:[0-5][0-9]:[0-5][0-9]|^>>'
    negate: true
    match: after
  fields:
    logtype: ds_log
    group: ${PLAT_GROUP}
    server: ${PLAT_SERVER}
    ipaddr: ${HOST_IP}
  fields_under_root: true
conf_tomcat
fi

#filebeat_install_conf
cat >> ${FLB_PATH}/filebeat.yml<<conf_tail
output.logstash:
  hosts: ["${ELK_IP}:${LOGS_PORT}"]
conf_tail
chown -R ${ELA_USER}.${ELA_USER} ${MON_HOME}/elastic

#filebeat_install_service
cat > /lib/systemd/system/filebeat.service<<filebeat_service
[Unit]
Description=Filebeat
Documentation=https://www.elastic.co/guide/en/beats/filebeat/current/index.html
Wants=network-online.target
After=network-online.target
[Service]
User=${ELA_USER}
Group=${ELA_USER}
ExecStart=${FLB_PATH}/filebeat -c ${FLB_PATH}/filebeat.yml
ExecStop=/bin/kill -SIGTERM $MAINPID
Restart=always
[Install]
WantedBy=multi-user.target
filebeat_service
chmod +x /lib/systemd/system/filebeat.service
systemctl daemon-reload 
systemctl start filebeat 
systemctl enable filebeat.service

#end
echo "`date +%F\ %T` filebeat安装完成"