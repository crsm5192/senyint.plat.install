#!/bin/sh
START_T=`date +%s` &>/dev/null
echo "`date +%F\ %T` 开始安装kafka"

#kafka_install_kafka
mkdir -p  $PLAT_HOME/kafka/logs
KAFKA_SOURCE=`ls ${INSTALL_DIR}/source |grep kafka`
tar zxvf ${INSTALL_DIR}/source/$KAFKA_SOURCE -C $PLAT_HOME/kafka/ 1>/dev/null
KAFKA_PATH=`ls ${PLAT_HOME}/kafka|grep kafka`
KAFKA_PATH=${PLAT_HOME}/kafka/${KAFKA_PATH}

#kafka_install_conf
mv ${KAFKA_PATH}/config/server.properties ${KAFKA_PATH}/config/server.propertiesbak
cat > ${KAFKA_PATH}/config/server.properties<<KFKCONF
broker.id=${KAFKA_ID}
listeners=PLAINTEXT://:9092
advertised.listeners=PLAINTEXT://${HOST_IP}:9092
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=${PLAT_HOME}/kafka/logs
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connect=${SVR_ID1}:${ZOO_PORT},${SVR_ID2}:${ZOO_PORT},${SVR_ID3}:${ZOO_PORT}
zookeeper.connection.timeout.ms=6000
group.initial.rebalance.delay.ms=0
KFKCONF
chown -R ${PLAT_USER}.${PLAT_USER} ${PLAT_HOME}/kafka


#kafka_install_service
cat > /lib/systemd/system/kafka.service<<KFKSRV
[Unit]
Description=Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=network.target remote-fs.target
After=network.target remote-fs.target nss-lookup.target zookeeper.service
[Service]
Type=forking
User=${PLAT_USER}
Group=${PLAT_USER}
Environment=JAVA_HOME=${JDK_PATH}
Environment=JMX_PORT=${KAFKA_JMX_PORT}
ExecStart=${KAFKA_PATH}/bin/kafka-server-start.sh -daemon ${KAFKA_PATH}/config/server.properties
ExecStop=${KAFKA_PATH}/bin/kafka-server-stop.sh
Restart=always
PrivateTmp=true
[Install]
WantedBy=multi-user.target
KFKSRV
chmod +x /usr/lib/systemd/system/kafka.service
systemctl daemon-reload 
systemctl start kafka
systemctl enable kafka.service

#kafka_install_firewall(){
firewall-cmd --zone=public --add-port=$KAFKA_PORT/tcp --permanent
firewall-cmd --zone=public --add-port=$KAFKA_JMX_PORT/tcp --permanent
firewall-cmd --reload

#end
echo "`date +%F\ %T` kafka安装完成,kafka目录${KAFKA_PATH},快照日志目录${PLAT_HOME}/kafka/log"