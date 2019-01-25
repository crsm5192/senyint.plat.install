#!/bin/sh

elastic_user_check(){
	id -u ${ELA_USER} &>/dev/null
	if [ $? = 1 ];then
        	groupadd -g 9200 ${ELA_USER} 1>/dev/null
        	useradd -g ${ELA_USER} -u 9200 ${ELA_USER} -s /bin/bash 1>/dev/null
	fi
}

elastic_patch(){
	export ELA_PATH=${MON_HOME}/elastic
	mkdir -p ${ELA_PATH}
	chown -R ${ELA_USER}.${ELA_USER} ${ELA_PATH}
}

elasticsearch_install(){
	elastic_user_check
	elastic_patch
	#elasticsearch_install
	ELS_SOURCE=`ls ${INSTALL_DIR}/source | grep elasticsearch`
	tar -zxvf  ${INSTALL_DIR}/source/$ELS_SOURCE -C ${ELA_PATH} 1>/dev/null
	ELS_PATH=`ls ${ELA_PATH} | grep elasticsearch`
	ELS_PATH=${ELA_PATH}/${ELS_PATH}
	chown -R ${ELA_USER}.${ELA_USER} ${ELS_PATH}
	#elasticsearch_conf
	sed -i "s@\#cluster.name: my-application@cluster.name: ${ELS_NAME}@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#node.name: node-1@node.name: ${ELS_NODE_NAME}@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#network.host: 192.168.0.1@network.host: ${HOST_IP}@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#http.port: 9200@http.port: ${ELS_PORT}@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#discovery.zen.minimum_master_nodes:@discovery.zen.minimum_master_nodes: ${ELS_NODE}@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#bootstrap.memory_lock: true@bootstrap.memory_lock: true@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#discovery.zen.ping.unicast.hosts: \[\"host1\", \"host2\"\]@discovery.zen.ping.unicast.hosts: ${ELS_NODE_HOST}@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#gateway.recover_after_nodes: 3@gateway.recover_after_nodes: 3@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#path.logs: /path/to/logs@path.logs: ${ELS_PATH}/logs@g" ${ELS_PATH}/config/elasticsearch.yml
	sed -i "s@\#path.data: /path/to/data@path.data: ${ELS_PATH}/data@g" ${ELS_PATH}/config/elasticsearch.yml
	#echo "xpack.security.enabled: false" >> ${ELS_PATH}/config/elasticsearch.yml
	#echo "xpack.monitoring.enabled: true" >> ${ELS_PATH}/config/elasticsearch.yml
	#echo "xpack.monitoring.collection.enabled: true" >> ${ELS_PATH}/config/elasticsearch.yml
	#elasticsearch_service
	cp -rf ${INSTALL_DIR}/scripts/elasticsearch /etc/init.d/elasticsearch
	sed -i "s#ELS_PATH=#&${ELS_PATH}#g" /etc/init.d/elasticsearch
	sed -i "s#ELS_USER=#&${ELA_USER}#g" /etc/init.d/elasticsearch
	sed -i "s#JDK_PATH=#&${JDK_PATH}#g" /etc/init.d/elasticsearch
	chmod +x /etc/init.d/elasticsearch
	#elastic_firewall
	firewall-cmd --zone=public --add-port=${ELS_PORT}/tcp --permanent
	firewall-cmd --zone=public --add-port=${ELS_TRA_PORT}/tcp --permanent
	firewall-cmd --reload
	echo "`date +%F\ %T` elasticsearch安装完成"
}

elasticsearch_install_master(){
	echo "node.master: true" >> ${ELS_PATH}/config/elasticsearch.yml
	echo "node.data: false" >> ${ELS_PATH}/config/elasticsearch.yml
	echo "node.ingest: true" >> ${ELS_PATH}/config/elasticsearch.yml
}

elasticsearch_install_node(){
	echo "node.master: false" >> ${ELS_PATH}/config/elasticsearch.yml
	echo "node.data: true" >> ${ELS_PATH}/config/elasticsearch.yml
	echo "node.ingest: true" >> ${ELS_PATH}/config/elasticsearch.yml
}

kibana_install(){
	elastic_user_check
	elastic_patch
	#kibana_install
	KIBA_SOURCE=`ls ${INSTALL_DIR}/source | grep kibana`
	tar -zxvf  ${INSTALL_DIR}/source/$KIBA_SOURCE -C ${ELA_PATH} 1>/dev/null
	KIBA_PATH=`ls ${ELA_PATH} | grep kibana`
	KIBA_PATH=${ELA_PATH}/${KIBA_PATH}
	mkdir -p ${KIBA_PATH}/log
	chown -R ${ELA_USER}.${ELA_USER} ${KIBA_PATH}
	#kibana_conf
	sed -i "s@\#server.port: 5601@server.port: 5601@g" ${KIBA_PATH}/config/kibana.yml
	sed -i "s@\#server.host: \"localhost\"@server.host: \"${HOST_IP}\"@g" ${KIBA_PATH}/config/kibana.yml
	sed -i "s@\#elasticsearch.url: \"http://localhost:9200\"@elasticsearch.url: \"http://${HOST_IP}:${ELS_PORT}\"@g" ${KIBA_PATH}/config/kibana.yml
	sed -i "s@\#pid.file: /var/run/kibana.pid@pid.file: ${KIBA_PATH}/kibana.pid@g" ${KIBA_PATH}/config/kibana.yml
	#kibana_service
	cp -rf ${INSTALL_DIR}/scripts/kibana /etc/init.d/kibana
	sed -i "s#KIBA_PATH=#&${KIBA_PATH}#g" /etc/init.d/kibana
	sed -i "s#ELS_USER=#&${ELA_USER}#g" /etc/init.d/kibana
	chmod +x /etc/init.d/kibana
	#kibana_firewall
	firewall-cmd --zone=public --add-port=${KIBA_PORT}/tcp --permanent
	firewall-cmd --reload
        echo "`date +%F\ %T` kibana安装完成"
}

logstash_install(){
	elastic_user_check
	elastic_patch
	#logstash_install
	LOGS_SOURCE=`ls ${INSTALL_DIR}/source | grep logstash`
	tar -zxvf  ${INSTALL_DIR}/source/$LOGS_SOURCE -C ${ELA_PATH} 1>/dev/null
	LOGS_PATH=`ls ${ELA_PATH} | grep logstash`
	LOGS_PATH=${ELA_PATH}/${LOGS_PATH}
	chown -R ${ELA_USER}.${ELA_USER} ${LOGS_PATH}
	#logstash_conf
	cp -rf ${INSTALL_DIR}/conf/logstash.conf ${LOGS_PATH}/config/logstash.conf
	#logstash_service
	cp -rf ${INSTALL_DIR}/scripts/logstash /etc/init.d/logstash
	sed -i "s#LOGS_PATH=#&${LOGS_PATH}#g" /etc/init.d/logstash
	sed -i "s#ELS_USER=#&${ELA_USER}#g" /etc/init.d/logstash
	sed -i "s#JDK_PATH=#&${JDK_PATH}#g" /etc/init.d/logstash
	chmod +x /etc/init.d/logstash
	#logstash_firewall
	firewall-cmd --zone=public --add-port=${LOGS_PORT}/tcp --permanent
	firewall-cmd --reload
        echo "`date +%F\ %T` logstash安装完成"
}