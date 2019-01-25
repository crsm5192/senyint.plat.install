#!/bin/sh

#start
echo "`date +%F\ %T` 开始安装zookeeper"

#zookeeper_install_path
mkdir -p  $PLAT_HOME/zookeeper/zkdata
mkdir -p  $PLAT_HOME/zookeeper/zkdatalog
mkdir -p  $PLAT_HOME/zookeeper/logs

#zookeeper_install_zookeeper
ZOO_SOURCE=`ls ${INSTALL_DIR}/source |grep zookeeper`
tar zxvf ${INSTALL_DIR}/source/$ZOO_SOURCE -C $PLAT_HOME/zookeeper/ 1>/dev/null
ZOO_PATH=`ls ${PLAT_HOME}/zookeeper|grep zookeeper`
ZOO_PATH=${PLAT_HOME}/zookeeper/${ZOO_PATH}

#zookeeper_install_conf
echo "${KAFKA_ID}" > $PLAT_HOME/zookeeper/zkdata/myid
cat > ${ZOO_PATH}/conf/zoo.cfg<<ZOOCONF
tickTime=2000
initLimit=10
syncLimit=5
dataDir=${PLAT_HOME}/zookeeper/zkdata
clientPort=${ZOO_PORT}
dataLogDir=${PLAT_HOME}/zookeeper/zkdatalog
server.${KAFKA_ID}=${SVR_ID1}:${ZOO_REG_PORT}
server.${KAFKA_ID}=${SVR_ID2}:${ZOO_REG_PORT}
server.${KAFKA_ID}=${SVR_ID3}:${ZOO_REG_PORT}
ZOOCONF
sed -i "s#zookeeper.log.dir=.#zookeeper.log.dir=${PLAT_HOME}\/zookeeper\/logs#g" ${ZOO_PATH}/conf/log4j.properties
sed -i "s#zookeeper.tracelog.dir=.#zookeeper.tracelog.dir=${PLAT_HOME}\/zookeeper\/logs#g" ${ZOO_PATH}/conf/log4j.properties
chown -R ${PLAT_USER}.${PLAT_USER} ${PLAT_HOME}/zookeeper

#zookeeper_install_service
cat > /lib/systemd/system/zookeeper.service<<ZOOSER
[Unit]
Description=Zookeper Server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target
[Service]
Type=forking
User=${PLAT_USER}
Group=${PLAT_USER}
Environment=JAVA_HOME=${JDK_PATH}
Environment=JMXPORT=${ZOO_JMX_PORT}
Environment=ZOO_LOG_DIR=${PLAT_HOME}/zookeeper/logs
ExecStart=${ZOO_PATH}/bin/zkServer.sh start
ExecStop=${ZOO_PATH}/bin/zkServer.sh stop
Restart=always
PrivateTmp=true
[Install]
WantedBy=multi-user.target
ZOOSER
chmod +x /usr/lib/systemd/system/zookeeper.service
systemctl daemon-reload 
systemctl start zookeeper 
systemctl enable zookeeper.service

#zookeeper_install_firewall
firewall-cmd --zone=public --add-port=$ZOO_PORT/tcp --permanent
firewall-cmd --zone=public --add-port=$ZOO_JMX_PORT/tcp --permanent
firewall-cmd --reload

#end
echo "`date +%F\ %T` zookeeper安装完成,zookeeper目录${ZOO_PATH},快照日志目录${PLAT_HOME}/zookeeper/zkdatalog"
