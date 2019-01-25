#!/bin/sh

echo "`date +%F\ %T` 开始安装完成grafana"

#grafana_user
id -u ${GRA_USER} &>/dev/null
if [ $? = 1 ];then
	groupadd -g 3000 ${GRA_USER} 1>/dev/null
        useradd -g ${GRA_USER} -u 3000 ${GRA_USER} -s /sbin/nologin 1>/dev/null
fi

#granfana_install
GRA_SOURCE=`ls ${INSTALL_DIR}/source |grep grafana`
tar zxvf ${INSTALL_DIR}/source/$GRA_SOURCE -C ${MON_HOME} 1>/dev/null
GRA_PATH=`ls ${MON_HOME}|grep grafana`
GRA_PATH=${MON_HOME}/${GRA_PATH}

#grafana_install_conf
chown -R ${GRA_USER}.${GRA_USER} ${GRA_PATH}
sed -i "s#/tmp/grafana.sock#grafana.sock#g" ${GRA_PATH}/conf/defaults.ini

#grafana_install_service
cp -rf ${INSTALL_DIR}/scripts/grafana.service /lib/systemd/system/grafana.service
sed -i "s#User=#&${GRA_USER}#g" /lib/systemd/system/grafana.service
sed -i "s#Group=#&${GRA_USER}#g" /lib/systemd/system/grafana.service
sed -i "s#ExecStart=#&${GRA_PATH}/bin/grafana-server#g" /lib/systemd/system/grafana.service
sed -i "s#WorkingDirectory=#&${GRA_PATH}#g" /lib/systemd/system/grafana.service
sed -i "s#config=#&${GRA_PATH}/conf/defaults.ini#g" /lib/systemd/system/grafana.service
sed -i "s#pidfile=#&${GRA_PATH}#g" /lib/systemd/system/grafana.service
sed -i "s#logs=#&${GRA_PATH}/data/log/grafana.log#g" /lib/systemd/system/grafana.service
sed -i "s#data=#&${GRA_PATH}/data#g" /lib/systemd/system/grafana.service
sed -i "s#plugins=#&${GRA_PATH}/data/plugins#g" /lib/systemd/system/grafana.service
sed -i "s#provisioning=#&${GRA_PATH}/conf/provisioning#g" /lib/systemd/system/grafana.service
sed -i "s#PIDFile=#&${GRA_PATH}/grafana-server.pid#g" /lib/systemd/system/grafana.service
systemctl daemon-reload
systemctl enable grafana.service
systemctl start grafana

#grafana_install_firewall
firewall-cmd --zone=public --add-port=${GRA_PORT}/tcp --permanent
firewall-cmd --reload

echo "`date +%F\ %T` grafana安装完成,kafka目录${GRA_PATH}"
