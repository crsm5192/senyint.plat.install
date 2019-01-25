#!/bin/sh

#start
echo "`date +%F\ %T` 开始安装平台node"

#node_install_node
echo "`date +%F\ %T` 开始安装node"
NODE_SOURCE=`ls ${INSTALL_DIR}/source | grep node-v`
tar xvf $INSTALL_DIR/source/${NODE_SOURCE} -C ${PLAT_HOME} 1>/dev/null
NODE_PATH=`ls ${PLAT_HOME} |grep node-v`
mv ${PLAT_HOME}/$NODE_PATH ${PLAT_HOME}/node
NODE_PATH=${PLAT_HOME}/node

#node_install_node_config
echo "`date +%F\ %T` 开始安装node-config"
NODE_CONFIG_SOURCE=`ls ${INSTALL_DIR}/source | grep node-config`
tar zxvf $INSTALL_DIR/source/${NODE_CONFIG_SOURCE} -C ${PLAT_HOME} 1>/dev/null
NODE_CONFIG_PATH=${PLAT_HOME}/node-config

#node_install_node_log
echo "`date +%F\ %T` 开始安装node-log-srv"
NODE_LOG_SOURCE=`ls ${INSTALL_DIR}/source | grep node-log`
tar zxvf $INSTALL_DIR/source/${NODE_LOG_SOURCE} -C ${PLAT_HOME} 1>/dev/null
NODE_LOG_PATH=${PLAT_HOME}/node-log-srv

#node_install_node_ui
echo "`date +%F\ %T` 开始安装node-ui"
NODE_UI_SOURCE=`ls ${INSTALL_DIR}/source | grep node-ui`
tar zxvf $INSTALL_DIR/source/${NODE_UI_SOURCE} -C ${PLAT_HOME} 1>/dev/null
NODE_UI_PATH=${PLAT_HOME}/node-ui

#node_install_web4node
echo "`date +%F\ %T` 开始安装web4node"
NODE_WEB_SOURCE=`ls ${INSTALL_DIR}/source | grep web4node`
tar zxvf $INSTALL_DIR/source/${NODE_WEB_SOURCE} -C ${PLAT_HOME} 1>/dev/null
NODE_WEB_PATH=${PLAT_HOME}/web4node

#node_install_node_bin
rm -rf /bin/node /bin/npm
ln -sf ${NODE_PATH}/bin/node /bin/node
ln -sf ${NODE_PATH}/bin/npm /bin/npm

#node_install_node_patch
mkdir -p ${PLAT_HOME}/change_logdb
mkdir -p ${PLAT_HOME}/node-eeb-center
mkdir -p ${PLAT_HOME}/node-eeb-client
ln -sf ${NODE_WEB_PATH}/public/t/paas/0function ${NODE_WEB_PATH}/private
ln -sf ${PLAT_HOME}/change_logdb ${NODE_WEB_PATH}/change_logdb
chown -R ${PLAT_USER}.${PLAT_USER} ${PLAT_HOME}/change_logdb
chown -R ${PLAT_USER}.${PLAT_USER} ${PLAT_HOME}/node*
chown -R ${PLAT_USER}.${PLAT_USER} ${PLAT_HOME}/web4node
source /etc/profile

#node_install_node_log_service
cat > /lib/systemd/system/node-log-srv.service<<NLS
[Unit]
Description=Node-Log-Srv
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=simple
Environment=HOME=${PLAT_HOME}
Environment=PATH=${NODE_PATH}/bin
User=${PLAT_USER}
Group=${PLAT_USER}
ExecStart=${NODE_PATH}/bin/node ${NODE_LOG_PATH}/index.js
ExecStop=${NODE_PATH}/bin/node ${NODE_LOG_PATH}/stop.js
Restart=always
WorkingDirectory=${NODE_LOG_PATH}
PIDFile=${NODE_LOG_PATH}/pid
PrivateTmp=true
[Install]
WantedBy=multi-user.target
NLS
systemctl daemon-reload
systemctl enable node-log-srv.service
systemctl start node-log-srv 

#node_install_node_ui_service
cat > /lib/systemd/system/node-ui.service<<NU
Description=Node-Ui
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=simple
Environment=HOME=${PLAT_HOME}
Environment=PATH=${NODE_PATH}/bin
User=${PLAT_USER}
Group=${PLAT_USER}
ExecStart=${NODE_PATH}/bin/node ${NODE_UI_PATH}/index.js
ExecStop=${NODE_PATH}/bin/node ${NODE_UI_PATH}/stop.js
Restart=always
PIDFile=${NODE_UI_PATH}/pid
WorkingDirectory=${NODE_UI_PATH}
PrivateTmp=true
[Install]
WantedBy=multi-user.target
NU
systemctl daemon-reload 
systemctl enable node-ui.service
systemctl start node-ui 

#web4node_install_firewall
firewall-cmd --zone=public --add-port=$NODE_UI_PORT/tcp --permanent
firewall-cmd --reload


#web4node_bakup
cp -rf ${INSTALL_DIR}/scripts/web4node_node_bakup.sh ${BAK_HOME}/scripts/
chmod +x ${BAK_HOME}/scripts/*
echo "0 1 * * * root /bin/bash /data/bakup/scripts/web4node_node_bakup.sh &>/dev/null" >> /etc/crontab

#end
echo "`date +%F\ %T` node平台安装完成,目录${PLAT_HOME}/node"
