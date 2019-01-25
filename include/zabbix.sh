#!/bin/bash

#start
echo "`date +%F\ %T` 开始安装zabbix-agent"

#zabbix_user_check
id -u ${ZBX_USER} &>/dev/null
if [ $? = 1 ];then
        groupadd -g 10050 ${ZBX_USER} 1>/dev/null
        useradd -g ${ZBX_USER} -u 10050 ${ZBX_USER} -s /bin/bash 1>/dev/null
fi
sed -i "s#anywhere#anywhere\nzabbix ALL=(root) NOPASSWD:/bin/netstat#g" /etc/sudoers

#zabbix_install
mkdir -p ${MON_HOME}/zabbix/log
mkdir -p ${MON_HOME}/zabbix/run
ZBX_SOURCE=`ls ${INSTALL_DIR}/source | grep zabbix`
tar -zxvf ${INSTALL_DIR}/source/$ZBX_SOURCE -C ${INSTALL_DIR}/tmp 1>/dev/null
ZBX_PATH=`ls ${INSTALL_DIR}/tmp | grep zabbix`
ZBX_PATH=${INSTALL_DIR}/tmp/${ZBX_PATH}
pushd ${ZBX_PATH} &>/dev/null
./configure \
	--prefix=${MON_HOME}/zabbix \
	--sysconfdir=${MON_HOME}/zabbix/etc \
	--with-ldap \
	--with-openssl \
	--enable-ipv6 \
	--enable-agent &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make -j ${THREAD} &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make install &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
export ZBX_PATH=${MON_HOME}/zabbix

#zabbix_install_conf
cat > ${ZBX_PATH}/etc/zabbix_agentd.conf<<zabbix_agent_conf
LogFile=${ZBX_PATH}/log/zabbix_agentd.log
LogFileSize=1
LogType=file
Server=${ZBX_IP}
ListenPort=${ZBX_AGENT_PORT}
ListenIP=${HOST_IP}
ServerActive=${ZBX_IP}
StartAgents=3
Hostname=${HOST_IP}
Include=${ZBX_PATH}/etc/zabbix_agentd.conf.d/*.conf
zabbix_agent_conf

#zabbix_item_jvm
cat > ${ZBX_PATH}/etc/zabbix_agentd.conf.d/jvm.conf<<JVM
UserParameter=jmx.jvm.discovery[*], python ${ZBX_PATH}/etc/scripts/jvm/jvm.py --list -g "$1" 2>/dev/null
UserParameter=jmx.jvm.item[*],python ${ZBX_PATH}/etc/scripts/jvm/jvm.py -b "$1" -k "$2" -p $3 2>/dev/null
JVM
cp -rf ${INSTALL_DIR}/scripts/jvm ${ZBX_PATH}/etc/scripts/

#zabbix_item_dscore
if [ ! -d "${PLAT_HOME}/dscore" ];then
	echo "`date +%F\ %T` 未安装dscore,不配置tomcat监控" 
else
	cat > ${ZBX_PATH}/etc/zabbix_agentd.conf.d/tomcat.conf<<tomcat
UserParameter=jmx.tomcat.discovery,python ${ZBX_PATH}/etc/scripts/tomcat/tomcat.py --list 2>/dev/null
UserParameter=jmx.tomcat.item[*],python ${ZBX_PATH}/etc/scripts/tomcat/tomcat.py -b "$1" -k "$2" -p $3 2>/dev/null	
tomcat
	cp -rf ${INSTALL_DIR}/scripts/tomcat ${ZBX_PATH}/etc/scripts/
	echo "`date +%F\ %T` 配置tomcat监控"
fi

#zabbix_item_nginx
if [ ! -d "${PLAT_HOME}/nginx" ];then
    echo "`date +%F\ %T` 未安装nginx,不配置nginx监控" 
else
	cat > ${ZBX_PATH}/etc/zabbix_agentd.conf.d/nginx.conf<<nginx
UserParameter=custom.nginx.discovery,python ${ZBX_PATH}/etc/scripts/nginx/nginx.py --list 2>/dev/null
UserParameter=custom.nginx.item[*],python ${ZBX_PATH}/etc/scripts/nginx/nginx.py -p $1 -k $2 2>/dev/null
nginx
	cp -rf ${INSTALL_DIR}/scripts/nginx ${ZBX_PATH}/etc/scripts/
	echo "`date +%F\ %T` 配置nginx监控"
fi

#zabbix_item_mysql
if [ ! -d "${PLAT_HOME}/mysql" ];then
	echo "`date +%F\ %T` 未安装mysql,不配置mysql监控" 
else
	cat > ${ZBX_PATH}/etc/zabbix_agentd.conf.d/mysql.conf<<mysql
UserParameter=mysql.status[*],python ${ZBX_PATH}/etc/scripts/mysql/mysql_status.py -i $1
UserParameter=mysql.function[*],python ${ZBX_PATH}/etc/scripts/mysql/mysql_func.py -i $1
UserParameter=mysql.perf[*],python ${ZBX_PATH}/etc/scripts/mysql//mysql_perf.py -i $1
mysql
	cp -rf ${INSTALL_DIR}/scripts/mysql ${ZBX_PATH}/etc/scripts/
	echo "`date +%F\ %T` 配置mysql监控"
fi

#zabbix_item_redis
if [ ! -d "${PLAT_HOME}/redis" ];then
	echo "`date +%F\ %T` 未安装redis,不配置redis监控" 
else
	cat > ${ZBX_PATH}/etc/zabbix_agentd.conf.d/redis.conf<<redis
UserParameter=custom.redis.discovery, python ${ZBX_PATH}/etc/scripts/redis/redis.py --list
UserParameter=custom.redis.item[*],python ${ZBX_PATH}/etc/scripts/redis/redis.py -p $1  -k $2
redis
	cp -rf ${INSTALL_DIR}/scripts/redis ${ZBX_PATH}/etc/scripts/
	echo "`date +%F\ %T` 配置redis监控"
fi

#zabbix_item_kafka
if [ ! -d "${PLAT_HOME}/kafka" ];then
	echo "`date +%F\ %T` 未安装kafka,不配置kafka监控" 
else
	cat > ${ZBX_PATH}/etc/zabbix_agentd.conf.d/kafka.conf<<kafka
UserParameter=kafka.topic.status[*], ${ZBX_PATH}/etc/scripts/kafka/kafka.sh $1
kafka
	cp -rf ${INSTALL_DIR}/scripts/kafka ${ZBX_PATH}/etc/scripts/
	echo "`date +%F\ %T` 配置kafka监控"
fi

#zabbix_item_zookeeper
if [ ! -d "${PLAT_HOME}/zookeeper" ];then
	echo "`date +%F\ %T` 未安装zookeeper,不配置zookeeper监控" 
else
	cat > ${ZBX_PATH}/etc/zabbix_agentd.conf.d/zookeeper.conf<<zookeeper
UserParameter=zookeeper.status[*], ${ZBX_PATH}/etc/scripts/zookeeper/zookeeper.sh $1
zookeeper
	cp -rf ${INSTALL_DIR}/scripts/zookeeper ${ZBX_PATH}/etc/scripts/
	echo "`date +%F\ %T` 配置zookeeper监控"
fi
chown -R ${ZBX_USER}.${ZBX_USER} ${ZBX_PATH}

#zabbix_install_service
cat > /lib/systemd/system/zabbix-agent.service<<zabbix_agent_service
[Unit]
Description=Zabbix Agent
After=syslog.target network.target
[Service]
Type=simple
ExecStart=${ZBX_PATH}/sbin/zabbix_agentd -c ${ZBX_PATH}/etc/zabbix_agentd.conf
ExecStop=/bin/kill -SIGTERM $MAINPID
Restart=on-failure
KillMode=control-group
RemainAfterExit=yes
PIDFile=${ZBX_PATH}/run/zabbix_agentd.pid
RestartSec=10s
TimeoutSec=0
[Install]
WantedBy=multi-user.target
zabbix_agent_service
chmod +x /lib/systemd/system/zabbix-agent.service
systemctl daemon-reload 
systemctl start zabbix-agent 
systemctl enable zabbix-agent.service

#zabbix_install_firewall
firewall-cmd --zone=public --add-port=${ZBX_AGENT_PORT}/tcp --permanent
firewall-cmd --reload

#end
echo "`date +%F\ %T` zabbix-agent安装完成"













