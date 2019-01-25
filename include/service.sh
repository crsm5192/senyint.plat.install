#!/bin/bash

#start
echo -e "`date +%F\ %T` 开始配置paas service"

#service
cat > /etc/init.d/paas<<SER
#!/bin/bash

color(){
if [ "\`systemctl status "\$1" |grep Active|awk '{print \$3}'\`" = "(running)" ];then &>/dev/null
        POINT="\033[32m\033[1m● "
else
        POINT="\033[31m\033[5m\033[1m● "
fi
MESAGE=\`systemctl status \$1 |grep Active\`
PID=\`systemctl status \$1 | grep "Main PID"\`
}
service_start(){

}

service_status(){

}

service_stop(){

}

service_restart(){

}

case "\$1" in
	start)
		service_start
	;;
	stop)
		service_stop
	;;
	restart)
		service_restart
	;;
	status)
		service_status
	;;
	*)
		echo $"Usage: \$0 {start|stop|restart|status}"
    ;;
esac

SER


#nginx
if [ ! -d "${PLAT_HOME}/nginx" ];then
    echo "`date +%F\ %T` 未安装nginx,不为paas配置nginx" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting Nginx...\"\nsystemctl start nginx#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor nginx\necho -e \"\${POINT}Nginx:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping Nginx...\"\nsystemctl stop nginx#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting Nginx...\"\nsystemctl restart nginx#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置nginx"
fi

#mysql
if [ ! -d "${PLAT_HOME}/mysql" ];then
    echo "`date +%F\ %T` 未安装mysql,不为paas配置mysql" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting MySql...\"\nsystemctl start mysqld#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor mysqld\necho -e \"\${POINT}MySql:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping MySql...\"\nsystemctl stop mysqld#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting MySql...\"\nsystemctl restart mysqld#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置mysql"
fi

#redis
if [ ! -d "${PLAT_HOME}/redis" ];then
    echo "`date +%F\ %T` 未安装redis,不为paas配置redis" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting Redis-Server...\"\nsystemctl start redis-server#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor redis-server\necho -e \"\${POINT}Redis-Server:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping Redis-Server...\"\nsystemctl stop redis-server#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting Redis-Server...\"\nsystemctl restart redis-server#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置redis"
fi

#zookeeper
if [ ! -d "${PLAT_HOME}/zookeeper" ];then
    echo "`date +%F\ %T` 未安装zookeeper,不为paas配置zookeeper" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting ZooKeeper...\"\nsystemctl start zookeeper#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor zookeeper\necho -e \"\${POINT}ZooKeeper:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping ZooKeeper...\"\nsystemctl stop zookeeper#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting ZooKeeper...\"\nsystemctl restart zookeeper#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置zookeeper"
fi

#kafka
if [ ! -d "${PLAT_HOME}/kafka" ];then
    echo "`date +%F\ %T` 未安装kafka,不为paas配置kafka" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting Kafka...\"\nsystemctl start kafka#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor kafka\necho -e \"\${POINT}Kafka:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping Kafka...\"\nsystemctl stop kafka#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting Kafka...\"\nsystemctl restart kafka#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置kafka"
fi

#nod-ui
if [ ! -d "${PLAT_HOME}/node-ui" ];then
    echo "`date +%F\ %T` 未安装node-ui,不为paas配置node-ui" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting Node-UI...\"\nsystemctl start node-ui#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor node-ui\necho -e \"\${POINT}Node-UI:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping Node-UI...\"\nsystemctl stop node-ui#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting Node-UI...\"\nsystemctl restart node-ui#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置node-ui"
fi

#nod-log
if [ ! -d "${PLAT_HOME}/node-log-srv" ];then
    echo "`date +%F\ %T` 未安装node-log-srv,不为paas配置node-log-srv" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting Node-Log...\"\nsystemctl start node-log-srv#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor node-log-srv\necho -e \"\${POINT}Node-Log:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping Node-Log...\"\nsystemctl stop node-log-srv#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting Node-Log...\"\nsystemctl restart node-log-srv#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置node-log-srv"
fi

#samba
if [ ! -d "${PLAT_HOME}/samba" ];then
    echo "`date +%F\ %T` 未安装smb,不为paas配置smb" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting Samba...\"\nsystemctl start smb#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor smb\necho -e \"\${POINT}Samba:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping Samba...\"\nsystemctl stop smb#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting Samba...\"\nsystemctl restart smb#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置smb"
fi

#squid
if [ ! -d "${PLAT_HOME}/squid" ];then
    echo "`date +%F\ %T` 未安装squid,不为paas配置squid" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting Squid...\"\nsystemctl start squid#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor squid\necho -e \"\${POINT}Squid:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping Squid...\"\nsystemctl stop squid#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting Squid...\"\nsystemctl restart squid#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置squid"
fi	

#dscore
if [ ! -d "${PLAT_HOME}/dscore" ];then
    echo "`date +%F\ %T` 未安装dscore,不为paas配置dscore" 
else
	sed -i "s#service_start(){#service_start(){\necho \"Starting DsCore...\"\nsystemctl start dscore#g" /etc/init.d/paas
	sed -i "s#service_status(){#service_status(){\ncolor dscore\necho -e \"\${POINT}DsCore:\\\033[0m\\\n\${MESAGE}\\\n\${PID}\"#g" /etc/init.d/paas
	sed -i "s#service_stop(){#service_stop(){\necho \"Stopping DsCore...\"\nsystemctl stop dscore#g" /etc/init.d/paas
	sed -i "s#service_restart(){#service_restart(){\necho \"ReStarting DsCore...\"\nsystemctl restart dscore#g" /etc/init.d/paas
	echo "`date +%F\ %T` 为paas配置dscore"
fi

#end
chmod +x /etc/init.d/paas
echo -e "`date +%F\ %T` 配置paas service完成"