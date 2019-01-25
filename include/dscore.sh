#!/bin/sh

#start
echo "`date +%F\ %T` 开始安装DsCore"

#dscore_path
mkdir -p ${PLAT_HOME}/ds-log
chown -R ${DS_USER}.${DS_USER} ${PLAT_HOME}/ds-log


#dscore_install_tomcat
TOMCAT_SOURCE=`ls ${INSTALL_DIR}/source | grep tomcat`
tar -zxvf  ${INSTALL_DIR}/source/${TOMCAT_SOURCE} -C ${PLAT_HOME} 1>/dev/null
export TOMCAT_PATH=${PLAT_HOME}/dscore

#dscore_install_ds
DS_SOURCE=`ls ${INSTALL_DIR}/source | grep ds`
tar -zxvf  ${INSTALL_DIR}/source/${DS_SOURCE} -C ${TOMCAT_PATH}/webapps 1>/dev/null

#dscore_install_tomcat_env
cat > ${TOMCAT_PATH}/bin/setenv.sh <<env
#!/bin/sh
#jdk
export JAVA_HOME=${JDK_PATH}
#jmx-remote-monitor
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote" 
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.port=${TOM_JMX_PORT}"
export CATALINA_OPTS="$CATALINA_OPTS -Djava.rmi.server.hostname=${HOST_IP}" 
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
export CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
#jvm gc-log
export CATALINA_OPTS="$CATALINA_OPTS -XX:+PrintGCDetails"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+PrintGCDateStamps"
export CATALINA_OPTS="$CATALINA_OPTS -Xloggc:${TOMCAT_PATH}/logs/gc.log"
export CATALINA_OPTS="$CATALINA_OPTS -XX:+PrintGCTimeStamps"
#jvm gc
#export CATALINA_OPTS="$CATALINA_OPTS -XX:+UseG1GC" 
#export CATALINA_OPTS="$CATALINA_OPTS -XX:MaxGCPauseMillis=50"
#export CATALINA_OPTS="$CATALINA_OPTS -Xmx1G"
#export CATALINA_OPTS="$CATALINA_OPTS -Xms1G" 
#export CATALINA_OPTS="$CATALINA_OPTS -Xmn256M"
#export CATALINA_OPTS="$CATALINA_OPTS -Xss512K"
env
chmod +x ${TOMCAT_PATH}/bin/setenv.sh

#dscore_conf
chmod o+r ${TOMCAT_PATH}/conf/server.xml
rm -rf /tmp/.server.xml
ln -sf ${TOMCAT_PATH}/conf/server.xml /tmp/.server.xml
chown -R ${DS_USER}.${DS_USER} ${TOMCAT_PATH}

#dscore_install_firewall
firewall-cmd --zone=public --add-port=${TOM_PORT}/tcp --permanent
firewall-cmd --zone=public --add-port=${TOM_JMX_PORT}/tcp --permanent
firewall-cmd --reload

#dscore_service
cat > /lib/systemd/system/dscore.service<<dscore_conf
[Unit]
Description=DsCore Server
After=syslog.target network.target
[Service]
Type=forking
User=${DS_USER}
Group=${DS_USER}
ExecStart=${TOMCAT_PATH}/bin/catalina.sh start
ExecStop=${TOMCAT_PATH}/bin/catalina.sh stop
Restart=always
PrivateTmp=true
[Install]
WantedBy=multi-user.target
dscore_conf
chmod +x /lib/systemd/system/dscore.service
systemctl daemon-reload 
systemctl enable dscore.service
systemctl start dscore

#tomcat_log_bakup
cp -rf ${INSTALL_DIR}/scripts/tomcat_log_backup.sh ${BAK_HOME}/scripts/
chmod +x ${BAK_HOME}/scripts/*
echo "1 0 * * * root /bin/bash /data/bakup/scripts/tomcat_log_backup.sh &>/dev/null" >> /etc/crontab

#END
echo "`date +%F\ %T` DsCore安装完成,tomcat目录${TOMCAT_PATH},应用目录${TOMCAT_PATH}/webapps/ds,应用日志目录${PLAT_HOME}/ds-log"

