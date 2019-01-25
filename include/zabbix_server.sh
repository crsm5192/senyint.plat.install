#!/bin/bash

#start
echo "`date +%F\ %T` 开始安装zabbix-server"

#zabbix_user_check
id -u ${ZBX_USER} &>/dev/null
if [ $? = 1 ];then
        groupadd -g 10050 ${ZBX_USER} 1>/dev/null
        useradd -g ${ZBX_USER} -u 10050 ${ZBX_USER} -s /bin/bash 1>/dev/null
fi

#mysql_check
ZBX_MYSQL=`find ${PLAT_HOME} -type f -name mysql_config` 1>/dev/null
[ $? -ne 0 ] && echo "请先安装mysql"

#zabbix_install_iksemel
ls ${MON_HOME}/lib | grep iksemel	&>/dev/null
if [ $? != 0 ];then
	echo "`date +%F\ %T` 安装iksemel模块"
	IKS_SOURCE=`ls ${INSTALL_DIR}/source | grep iksemel`
	tar -zxvf ${INSTALL_DIR}/source/$IKS_SOURCE -C ${INSTALL_DIR}/tmp 1>/dev/null
	IKS_PATH=`ls ${INSTALL_DIR}/tmp | grep iksemel`
	IKS_PATH=${INSTALL_DIR}/tmp/${IKS_PATH}
	pushd ${IKS_PATH} &>/dev/null
		./configure --prefix=${MON_HOME}/lib/iksemel 1>/dev/null
		[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
	make -j ${THREAD} &>/dev/null
	[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
	make install &>/dev/null
	[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
	export IKS_PATH=${MON_HOME}/lib/iksemel
	ln -sf ${IKS_PATH}/lib/libiksemel.so.3 /lib64/
	echo "`date +%F\ %T` 安装iksemel模块完成,iksemel目录${IKS_PATH}"	
else
	IKS_PATH=`ls ${MON_HOME}/lib | grep iksemel`
	export IKS_PATH=${MON_HOME}/lib/$IKS_PATH
	echo "`date +%F\ %T` iksemel模块已安装至${IKS_PATH}"
fi

#zabbix_install
echo "`date +%F\ %T` 开始编译安装zabbix-server"
mkdir -p ${MON_HOME}/zabbix/log
mkdir -p ${MON_HOME}/zabbix/run
mkdir -p ${MON_HOME}/zabbix/web
ZBX_SOURCE=`ls ${INSTALL_DIR}/source | grep zabbix`
tar -zxvf ${INSTALL_DIR}/source/$ZBX_SOURCE -C ${INSTALL_DIR}/tmp 1>/dev/null
ZBX_PATH=`ls ${INSTALL_DIR}/tmp | grep zabbix`
ZBX_PATH=${INSTALL_DIR}/tmp/${ZBX_PATH}
pushd ${ZBX_PATH} &>/dev/null
./configure \
	--prefix=${MON_HOME}/zabbix \
	--sysconfdir=${MON_HOME}/zabbix/etc \
 	--enable-server \
	--enable-agent \
 	--with-mysql=${ZBX_MYSQL} \
	--with-net-snmp \
	--with-libcurl \
	--with-libxml2 \
	--enable-proxy \
	--enable-ipv6 \
	--with-ssh2 \
	--with-iconv \
	--with-openipmi \
	--with-ldap \
	--with-openssl \
	--with-jabber=${IKS_PATH} 1>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make -j ${THREAD} &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make install &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"

#zabbix_install_web
echo "`date +%F\ %T` 配置zabbix-web"
mv ${ZBX_PATH}/frontends/php ${MON_HOME}/zabbix/web/zabbix
cp -rf ${INSTALL_DIR}/conf/web/phpinfo.php ${MON_HOME}/zabbix/web/zabbix/phpinfo.php
cp -rf ${INSTALL_DIR}/conf/web/p.php ${MON_HOME}/zabbix/web/zabbix/p.php
cp -rf ${INSTALL_DIR}/conf/web/ocp.php ${MON_HOME}/zabbix/web/zabbix/ocp.php
chown -R ${NGX_USER}.${NGX_USER} ${MON_HOME}/zabbix/web/zabbix

#zabbix_install_db
echo "`date +%F\ %T` 配置zabbix db"
mysql -u root -p${MYSQL_PASSWD} -e "create database ${ZBX_DB} character set utf8 collate utf8_bin; \
                grant all privileges on ${ZBX_DB}.* to ${ZBX_DB_USER}@${MON_IP} identified by '${ZBX_DB_PASSWD}'; \
                flush privileges;" &>/dev/null
mysql -u root -p${MYSQL_PASSWD} zabbix < ${ZBX_PATH}/database/mysql/schema.sql &>/dev/null
mysql -u root -p${MYSQL_PASSWD} zabbix < ${ZBX_PATH}/database/mysql/images.sql &>/dev/null
mysql -u root -p${MYSQL_PASSWD} zabbix < ${ZBX_PATH}/database/mysql/data.sql &>/dev/null

#zabbix_install_conf
echo "`date +%F\ %T` 配置zabbix配置文件"
cat > ${MON_HOME}/zabbix/etc/zabbix_server.conf<<zabbix_server_conf
LogFile=${MON_HOME}/zabbix/log/zabbix_server.log
LogFileSize=1
ListenPort=10051
PidFile=${MON_HOME}/zabbix/zabbix_server.pid
SocketDir=${MON_HOME}/zabbix/run
DBHost=${HOST_IP}
DBName=${ZBX_DB}
DBUser=${ZBX_DB_USER}
DBPassword=${ZBX_DB_PASSWD}
DBSocket=${MYSQL_PATH}/sock/mysql.sock
Timeout=4
StartPollers=20
SNMPTrapperFile==${MON_HOME}/zabbix/log/snmptrap.log
AlertScriptsPath=${MON_HOME}/zabbix/share/zabbix/alertscripts
ExternalScripts=${MON_HOME}/zabbix/share/zabbix/externalscripts:
LogSlowQueries=3000
zabbix_server_conf

cat > ${MON_HOME}/zabbix/etc/zabbix_agentd.conf<<zabbix_agent_conf
LogFile=${MON_HOME}/zabbix/log/zabbix_agentd.log
LogFileSize=1
LogType=file
Server=${ZBX_IP}
ListenPort=${ZBX_AGENT_PORT}
ListenIP=${HOST_IP}
ServerActive=${ZBX_IP}
StartAgents=3
Hostname=${HOST_IP}
Include=${MON_HOME}/zabbix/etc/zabbix_agentd.conf.d/*.conf
zabbix_agent_conf

cat >> ${PLAT_HOME}/nginx/conf/location.conf<<web_conf
location /zabbix {
	include enable-php.conf;
	index index.php;
	root ${MON_HOME}/zabbix/web/;
}
web_conf
systemctl reload nginx

#zabbix_install_service
echo "`date +%F\ %T` 添加zabbix系统服务"
cat > /lib/systemd/system/zabbix-server.service<<zabbix_server_service
[Unit]
Description=Zabbix Server
After=syslog.target network.target mysqld.service
[Service]
Type=simple
ExecStart=${MON_HOME}/zabbix/sbin/zabbix_server -c ${MON_HOME}/zabbix/etc/zabbix_server.conf
ExecReload=${MON_HOME}/zabbix/sbin/zabbix_server -R config_cache_reload
ExecStop=/bin/kill -SIGTERM $MAINPID
Restart=on-failure
KillMode=control-group
RemainAfterExit=yes
PIDFile=${MON_HOME}/zabbix/run/zabbix_server.pid
RestartSec=10s
TimeoutSec=0
[Install]
WantedBy=multi-user.target
zabbix_server_service

cat > /lib/systemd/system/zabbix-agent.service<<zabbix_agent_service
[Unit]
Description=Zabbix Agent
After=syslog.target network.target
[Service]
Type=simple
ExecStart=${MON_HOME}/zabbix/sbin/zabbix_agentd -c ${MON_HOME}/zabbix/etc/zabbix_agentd.conf
ExecStop=/bin/kill -SIGTERM $MAINPID
Restart=on-failure
KillMode=control-group
RemainAfterExit=yes
PIDFile=${MON_HOME}/zabbix/run/zabbix_agentd.pid
RestartSec=10s
TimeoutSec=0
[Install]
WantedBy=multi-user.target
zabbix_agent_service

systemctl daemon-reload 
systemctl enable zabbix-agent.service
systemctl enable zabbix-server.service
systemctl start zabbix-agent.service 
systemctl start zabbix-server.service


#zabbix_install_firewall
echo "`date +%F\ %T` 防火墙开放zabbix端口"
firewall-cmd --zone=public --add-port=${ZBX_SERVER_PORT}/tcp --permanent
firewall-cmd --zone=public --add-port=${ZBX_AGENT_PORT}/tcp --permanent
firewall-cmd --reload

#end
echo "`date +%F\ %T` 安装zabbix-server完成"


