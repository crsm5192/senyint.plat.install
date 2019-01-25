#!/bin/sh

root_user_check(){   
        if [ `id -u` != 0 ];then
		echo -e "`date +%F\ %T` 请使用\033[31mroot\033[0m用户运行安装脚本"
		exit 1
        fi
}

plat_user_check(){
	id -u $PLAT_USER  &>/dev/null  
	if [ $? != 0 ];then
		groupadd -g 8080 $PLAT_USER &>/dev/null
		useradd -g $PLAT_USER  -u 8080 $PLAT_USER &>/dev/null
		chmod 755 ${PLAT_HOME}
		echo -e "`date +%F\ %T` 平台用户\033[31m${PLAT_USER}\033[0m已成功创建"
	fi  
}

install_tools(){
	if [ ! -f "/root/.tools.lock" ];then
		echo "`date +%F\ %T` 清除yum安装历史"
		yum clean all &>/dev/null
		rm -rf /var/lib/yum/history/*.sqlite
		#install_epel_repo
		echo "`date +%F\ %T` 安装elep软件源"
		rpm -ivh ${INSTALL_DIR}/rpm/epel-release-7-11.noarch.rpm &>/dev/null
		#update_yum_cache
		echo "`date +%F\ %T` 开始更新yum cache"
		rm -rf /var/cache/yum 
		YUM_SOURCE=`ls ${INSTALL_DIR}/source |grep yum`
		tar zxvf ${INSTALL_DIR}/source/${YUM_SOURCE} -C /var/cache 1>/dev/null
		echo "`date +%F\ %T` 更新yum cache完成"	
		#install_tools
		echo "`date +%F\ %T` 开始安装软件包及支持库"
		yum -y localinstall ${INSTALL_DIR}/rpm/* 1>/dev/null
		echo "`date +%F\ %T` 安装软件包及支持库完成"
		#update_ntp.conf
		echo "`date +%F\ %T` 更新ntp配置"
		ntpdate -u ntp.api.bz
		echo "0 */3 * * * root /usr/sbin/ntpdate -u ntp.api.bz &>/dev/null" >> /etc/crontab
		mv /etc/ntp.conf /etc/ntp.confbak
		cat > /etc/ntp.conf<<ntp_conf
driftfile /var/lib/ntp/ntp.drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1
disable monitor
restrict 10.10.0.0 mask 255.255.0.0 nomodify notrap
server ntp01.jzwjj.gov.cn prefer
server ntp02.jzwjj.gov.cn prefer
server cn.pool.ntp.org prefer
server ntp.api.bz   prefer
server ntp.sjtu.edu.cn  prefer
server 130.149.17.21
server 127.127.1.0
fudge 127.127.1.0 stratum 8
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
ntp_conf
		touch /root/.tools.lock                
	fi
}

system_config(){
	if [ ! -f "/root/.systemconfig.lock" ];then
		#selinux_off
		echo "`date +%F\ %T` 关闭selinux"
		sed -i 's#enforcing#disabled#g' /etc/selinux/config 1>/dev/null
		setenforce 0
		#timezone
		echo -e "`date +%F\ %T` 更改时区为\033[31m上海\033[0m"
		cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &>/dev/null
		#limits_openfile
		echo "`date +%F\ %T` 优化文件打开数"		
		sed -i "s@\# End of file@*     soft   nproc   65535\n\# End of file@g" /etc/security/limits.conf
		sed -i "s@\# End of file@*     hard   nproc   65535\n\# End of file@g" /etc/security/limits.conf
		sed -i "s@\# End of file@*     soft   nofile  65536\n\# End of file@g" /etc/security/limits.conf
		sed -i "s@\# End of file@*     hard   nofile  65536\n\# End of file@g" /etc/security/limits.conf
		sed -i "s@\# End of file@*     soft   memlock unlimited\n\# End of file@g" /etc/security/limits.conf
		sed -i "s@\# End of file@*     hard   memlock unlimited\n\# End of file@g" /etc/security/limits.conf
		echo "vm.swappiness = 1" >> /etc/sysctl.conf
		echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
		echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
		echo "net.core.somaxconn= 1024" >> /etc/sysctl.conf
		/sbin/sysctl -p 1>/dev/null
		echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
		#hostname
		echo -e "`date +%F\ %T` 修改hostname为\033[31m${HOST_NAME}\033[0m"
		echo "${HOST_NAME}" >/etc/hostname
		hostname $HOST_NAME
		#hosts
		echo "127.0.0.1 ${HOST_NAME}" >>/etc/hosts
		echo "${HOST_IP} ${HOST_NAME}" >>/etc/hosts
		#pub-key
		echo -e "`date +%F\ %T` 部署\033[31m${ANS_IP}\033[0m公钥"
		mkdir -p /root/.ssh
		cp -rf ${INSTALL_DIR}/conf/authorized_keys/${ANS_IP} /root/.ssh/authorized_keys
		touch /root/.systemconfig.lock
	fi
}

jdk_install(){
	ls ${PLAT_HOME}/lib | grep jdk &>/dev/null
	if [ $? != 0 ];then
		echo "`date +%F\ %T` 开始安装JDK"
		JDK_SOUREC=`ls ${INSTALL_DIR}/source |grep jdk`
		tar zxvf ${INSTALL_DIR}/source/${JDK_SOUREC} -C ${PLAT_HOME}/lib 1>/dev/null
		JDK_PATH=`ls ${PLAT_HOME}/lib | grep jdk`
		export JDK_PATH=${PLAT_HOME}/lib/${JDK_PATH}
		echo "`date +%F\ %T` JDK安装完成,JDK目录${JDK_PATH}"
		
	else
		JDK_PATH=`ls ${PLAT_HOME}/lib | grep jdk`
		export	JDK_PATH=${PLAT_HOME}/lib/${JDK_PATH}
		echo "`date +%F\ %T` JDK已安装至${JDK_PATH}"
	fi
	chown -R ${PLAT_USER}.${PLAT_USER} ${JDK_PATH}
}

jemalloc_install(){
	ls ${PLAT_HOME}/lib | grep jemalloc &>/dev/null
    if [ $? != 0 ];then
		echo "`date +%F\ %T` 开始安装jemalloc模块"
       	JEMALLOC_SOURCE=`ls ${INSTALL_DIR}/source | grep jemalloc`
        tar jxvf ${INSTALL_DIR}/source/${JEMALLOC_SOURCE} -C ${INSTALL_DIR}/tmp 1>/dev/null
        JEMALLOC_SETUP=`ls ${INSTALL_DIR}/tmp | grep jemalloc`
        pushd ${INSTALL_DIR}/tmp/${JEMALLOC_SETUP} &>/dev/null
			./configure --prefix=${PLAT_HOME}/lib/jemalloc 1>/dev/null
			[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
        make -j ${THREAD} 1>/dev/null
		[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
		make install 1>/dev/null
		[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"	
		export JEMALLOC_PATH=${PLAT_HOME}/lib/jemalloc
		ln -sf ${JEMALLOC_PATH}/lib/libjemalloc.so.2 /usr/lib64/libjemalloc.so.1
		mkdir -p /etc/ld.so.conf.d
		echo "${JEMALLOC_PATH}/lib/" > /etc/ld.so.conf.d/jemalloc.conf
		/sbin/ldconfig
		echo "`date +%F\ %T` 安装jemalloc模块完成,jemalloc目录${JEMALLOC_PATH}"
	else
		JEMALLOC_PATH=`ls ${PLAT_HOME}/lib | grep jemalloc`
		export JEMALLOC_PATH=${PLAT_HOME}/lib/${JEMALLOC_PATH}
		echo "`date +%F\ %T` jemalloc模块已安装至${JEMALLOC_PATH}"
	fi
	chown -R ${PLAT_USER}.${PLAT_USER} ${JEMALLOC_PATH}
}

luajit_install(){
	ls ${PLAT_HOME}/lib | grep luajit	&>/dev/null
	if [ $? != 0 ];then
		echo "`date +%F\ %T` 安装LuaJIT模块"
		LuaJIT_SOURCE=`ls ${INSTALL_DIR}/source | grep luajit2`
		tar zxvf $INSTALL_DIR/source/$LuaJIT_SOURCE -C $INSTALL_DIR/tmp 1>/dev/null
		LuaJIT_PATH=`ls $INSTALL_DIR/tmp | grep luajit2`
		LuaJIT_PATH=$INSTALL_DIR/tmp/${LuaJIT_PATH}
		pushd ${LuaJIT_PATH} &>/dev/null
        	make -j ${THREAD} PREFIX=${PLAT_HOME}/lib/luajit &>/dev/null
		[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
		make install PREFIX=${PLAT_HOME}/lib/luajit &>/dev/null
		[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"				
		export LuaJIT_PATH=${PLAT_HOME}/lib/luajit
		export LUAJIT_LIB=${LuaJIT_PATH}/lib
		export LUAJIT_INC=${LuaJIT_PATH}/include/luajit-2.1
        mkdir -p /etc/ld.so.conf.d
        echo "${LuaJIT_PATH}/lib/" > /etc/ld.so.conf.d/luajit.conf
        /sbin/ldconfig
		echo "`date +%F\ %T` 安装LuaJIT模块完成,LuaJIT目录${LuaJIT_PATH}"		
	else
		LuaJIT_PATH=`ls ${PLAT_HOME}/lib | grep luajit`
		export LuaJIT_PATH=${PLAT_HOME}/lib/$LuaJIT_PATH
		export LUAJIT_LIB=${LuaJIT_PATH}/lib
		export LUAJIT_INC=${LuaJIT_PATH}/include/luajit-2.1
		echo "`date +%F\ %T` LuaJIT模块已安装至${LuaJIT_PATH}"
fi
}

kafka_single(){
			export KAFKA_ID=1
			#echo $KAFKA_ID
			export SVR_ID1=$HOST_IP
			#echo $SVR_ID1
			export SVR_ID2=$HOST_IP
			#echo $SVR_ID2
			export SVR_ID3=$HOST_IP
			#echo $SVR_ID3
}

kafka_cluster(){
			echo "请输入当前kafka服务器集群序号{1|2|3}:"
			read CHAR
			export KAFKA_ID=$CHAR
			#echo $KAFKA_ID
			echo -e "请输入集群ID\033[31m1\033[0m的IP地址:"
			read CHAR
			export SVR_ID1=$CHAR
			#echo $SVR_ID1
			echo -e "请输入集群ID\033[31m2\033[0m的IP地址:"
			read CHAR
			export SVR_ID2=$CHAR
			#echo $SVR_ID2
			echo -e "请输入集群ID\033[31m3\033[0m的IP地址:"
			read CHAR
			export SVR_ID3=$CHAR
			#echo $SVR_ID3
}

filebeat_conf(){
	printf "			
		1：基层卫生
		2：数据平台
		3: 综合管理平台
		4：医保监管平台
		5：测试服务器
"
	echo -e "请输入当前服务器组(输入数字1|2|3|4...即可):"
	read CHAR
	case $CHAR in
		1)
			export PLAT_GROUP=基层卫生
		;;
		2)
			export PLAT_GROUP=数据平台
		;;
		3)
			export PLAT_GROUP=综合管理平台
		;;
		4)
			export PLAT_GROUP=医保监管平台
		;;
		5)
			export PLAT_GROUP=测试服务器					
		;;
		*)
			echo "不支持的选项"	
		;;
	esac
	echo -e "当前服务器组别为${PLAT_GROUP}"
	printf "			
		1：入口
		2：DsCore
"
	echo  "请输入当前服务器角色(输入数字1|2...即可):"
	read CHAR
	case $CHAR in
		1)
			export PLAT_SERVER=入口
		;;
		2)
			export PLAT_SERVER=DsCore
		;;
		*)
			echo "不支持的选项"	
		;;
	esac
	export PLAT_SERVER="${PLAT_GROUP}-${PLAT_SERVER}-"`echo ${HOST_IP}|awk -F. '{print $4}'`""	
	echo -e "当前服务器角色为：\033[31m${PLAT_SERVER}\033[0m"		
}	
	
share_path(){
	echo  "请输入共享存储需要挂载的目的服务器IP(samba服务端,一般为该集群入口服务器):"
	read CHAR
	export SMB_IP=$CHAR
}

plat_all_single(){
	filebeat_conf
	kafka_single
	plat_user_check
	system_config
	install_tools
	jdk_install
	jemalloc_install
	luajit_install
	#nginx		
	/bin/sh ${INSTALL_DIR}/include/nginx.sh
	#dscore
	/bin/sh ${INSTALL_DIR}/include/dscore.sh
	#mysql
	/bin/sh ${INSTALL_DIR}/include/mysql.sh
	#redis
	/bin/sh ${INSTALL_DIR}/include/redis.sh
	#node
	/bin/sh ${INSTALL_DIR}/include/node.sh
	#zookeeper
	/bin/sh ${INSTALL_DIR}/include/zookeeper.sh
	#kafka
	/bin/sh ${INSTALL_DIR}/include/kafka.sh 
	#samba
	.  ${INSTALL_DIR}/include/samba.sh
	samba_install_prepare
	samba_install_server
	#squid
	/bin/sh ${INSTALL_DIR}/include/squid.sh
	#filebeat
	/bin/sh ${INSTALL_DIR}/include/filebeat.sh
	#zabbix
	/bin/sh ${INSTALL_DIR}/include/zabbix.sh
	#service
	/bin/sh ${INSTALL_DIR}/include/service.sh
}

plat_all_cluster(){
	filebeat_conf
	kafka_cluster
	plat_user_check
	system_config	
	install_tools
	jdk_install
	jemalloc_install
	luajit_install
	#nginx		
	/bin/sh ${INSTALL_DIR}/include/nginx.sh
	#dscore
	/bin/sh ${INSTALL_DIR}/include/dscore.sh
	#mysql
	/bin/sh ${INSTALL_DIR}/include/mysql.sh
	#redis
	/bin/sh ${INSTALL_DIR}/include/redis.sh
	#node
	/bin/sh ${INSTALL_DIR}/include/node.sh
	#zookeeper
	/bin/sh ${INSTALL_DIR}/include/zookeeper.sh
	#kafka
	/bin/sh ${INSTALL_DIR}/include/kafka.sh 
	#samba
	.  ${INSTALL_DIR}/include/samba.sh
	samba_install_prepare
	samba_install_server
	#squid
	/bin/sh ${INSTALL_DIR}/include/squid.sh	
	#filebeat
	/bin/sh ${INSTALL_DIR}/include/filebeat.sh
	#zabbix
	/bin/sh ${INSTALL_DIR}/include/zabbix.sh
	#service
	/bin/sh ${INSTALL_DIR}/include/service.sh
}

plat_without_dscore(){
	filebeat_conf
	kafka_single
	plat_user_check
	system_configg	
	install_tools
	jdk_install
	jemalloc_install
	luajit_install
	#nginx		
	/bin/sh ${INSTALL_DIR}/include/nginx.sh
	#mysql
	/bin/sh ${INSTALL_DIR}/include/mysql.sh
	#redis
	/bin/sh ${INSTALL_DIR}/include/redis.sh
	#node
	/bin/sh ${INSTALL_DIR}/include/node.sh
	#zookeeper
	/bin/sh ${INSTALL_DIR}/include/zookeeper.sh
	#kafka
	/bin/sh ${INSTALL_DIR}/include/kafka.sh 
	#samba
	.  ${INSTALL_DIR}/include/samba.sh
	samba_install_prepare
	samba_install_server
	#squid
	/bin/sh ${INSTALL_DIR}/include/squid.sh	
	#filebeat
	/bin/sh ${INSTALL_DIR}/include/filebeat.sh
	#zabbix
	/bin/sh ${INSTALL_DIR}/include/zabbix.sh
	#service
	/bin/sh ${INSTALL_DIR}/include/service.sh
}

palt_dscore(){
	filebeat_conf
	share_path
	plat_user_check
	system_config
	install_tools
	jdk_install
	#samba
	.  ${INSTALL_DIR}/include/samba.sh
	samba_install_prepare
	samba_install_client
	#dscore
	/bin/sh ${INSTALL_DIR}/include/dscore.sh 
}

install_nginx(){
	plat_user_check
	system_config
	install_tools
	jemalloc_install
	luajit_install
	if [ ! -d "${PLAT_HOME}/nginx" ];then
		#nginx		
		/bin/sh ${INSTALL_DIR}/include/nginx.sh
	else
		export NGX_PATH=${PLAT_HOME}/nginx
	fi
}

install_mysql(){
	plat_user_check
	system_config
	install_tools
	jemalloc_install
	if [ ! -d "${PLAT_HOME}/mysql" ];then
		#mysql		
		/bin/sh ${INSTALL_DIR}/include/mysql.sh
	else
		export MYSQL_PATH=${PLAT_HOME}/mysql
	fi
}

install_php(){
	plat_user_check
	system_config
	install_tools
	if [ ! -d "${PLAT_HOME}/php" ];then
		#php		
		/bin/sh ${INSTALL_DIR}/include/php.sh
	else
		export PHP_PATH=${PLAT_HOME}/php
	fi
}

plat_kafka_single(){
	afka_single
	plat_user_check
	system_config
	install_tools
	jdk_install
	#zookeeper
	/bin/sh ${INSTALL_DIR}/include/zookeeper.sh
	#kafka
	/bin/sh ${INSTALL_DIR}/include/kafka.sh
}

palt_kafka_cluster(){
	kafka_cluster
	plat_user_check
	system_config
	install_tools
	jdk_install
	#zookeeper
	/bin/sh ${INSTALL_DIR}/include/zookeeper.sh
	#kafka
	/bin/sh ${INSTALL_DIR}/include/kafka.sh 
}

plat_node(){
	plat_user_check
	system_config
	install_tools
	#node
	/bin/sh ${INSTALL_DIR}/include/node.sh
}

install_redis(){
	plat_user_check
	system_config
	install_tools
	#redis
	/bin/sh ${INSTALL_DIR}/include/redis.sh
}

install_filebeat(){
	filebeat_conf
	plat_user_check
	system_config
	install_tools			
	#filebeat
	/bin/sh ${INSTALL_DIR}/include/filebeat.sh
}

install_zabbix_agent(){
	plat_user_check
	system_config
	install_tools
	jdk_install
	#zabbix
	/bin/sh ${INSTALL_DIR}/include/zabbix.sh
}

install_samba(){
	plat_user_check
	system_config
	install_tools
	#samba
	.  ${INSTALL_DIR}/include/samba.sh
	samba_install_prepare
	samba_install_server
	#squid
	/bin/sh ${INSTALL_DIR}/include/squid.sh
}

install_squid(){
	plat_user_check
	system_config
	install_tools
	#squid
	/bin/sh ${INSTALL_DIR}/include/squid.sh
}

monitor_elastic_all(){
	plat_user_check
	system_config
	install_tools
	jdk_install
	#elasticsearch
	. ${INSTALL_DIR}/include/elastic.sh
	elasticsearch_install
	elasticsearch_install_master
	#kibana
	kibana_install
	logstash
	logstash_install 
}

monitor_elasticsearch_master(){
	plat_user_check
	system_config		
	install_tools
	jdk_install	
	#elasticsearch_master		
	. ${INSTALL_DIR}/include/elastic.sh
	elasticsearch_install
	elasticsearch_install_master
}

monitor_elasticsearch_node(){
	plat_user_check
	system_config		
	install_tools
	jdk_install	
	#elasticsearch_master		
	. ${INSTALL_DIR}/include/elastic.sh
	elasticsearch_install
	elasticsearch_install_node
}

monitor_kibana(){
	plat_user_check
	system_config
	install_tools
	#kibana
	. ${INSTALL_DIR}/include/elastic.sh
	kibana_install
}

monitor_logstash(){
	plat_user_check
	system_config
	install_tools
	#kibana
	. ${INSTALL_DIR}/include/elastic.sh
	logstash_install
}

monitor_grafana(){
	plat_user_check
	system_config
	install_tools			
	#grafana
	/bin/sh ${INSTALL_DIR}/include/grafana.sh
}

monitor_zabbix_server(){
	plat_user_check
	system_config
	install_tools
	jemalloc_install
	luajit_install
	#nginx		
	install_nginx
	#mysql
	install_mysql
	#php
	install_php
	#zabbix
	/bin/sh ${INSTALL_DIR}/include/zabbix_server.sh
}

monitor_ansible(){
	plat_user_check
	system_config
	install_tools
	#ansible
	/bin/sh ${INSTALL_DIR}/include/ansible.sh
}

install_package(){
	clear
	rm -rf ${INSTALL_DIR}/tmp
	mkdir -p ${INSTALL_DIR}/tmp
	mkdir -p ${PLAT_HOME}/lib
	mkdir -p ${BAK_HOME}/scripts
	mkdir -p ${MON_HOME}/lib
	printf "
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\033[31m平台\033[0m<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
#	输入 \033[31m p  \033[0m:安装全部平台应用(samba server模式|kafka|zookeeper单节点)      #
#	输入 \033[31m pc \033[0m:安装全部平台应用(samba server模式|kafka|zookeeper集群3节点)   #
#	输入 \033[31m rk \033[0m:安装平台入口服务(samba server模式|kafka单节点|不含dscore)     #
#	输入 \033[31m d  \033[0m:安装后台核心服务(JDK DsCore|samba client模式)                 #
#	输入 \033[31m n  \033[0m:安装nginx & jemalloc模块                                      #
#	输入 \033[31m m  \033[0m:安装mysql & jemalloc模块                                      #
#	输入 \033[31m k  \033[0m:安装kafka,独立zookeeper & JDK(单节点安装)                     #
#	输入 \033[31m kc \033[0m:安装kafka,独立zookeeper & JDK(集群安装限3节点)                #
#	输入 \033[31m nj \033[0m:安装node平台                                                  #
#	输入 \033[31m r  \033[0m:安装redis                                                     #
#	输入 \033[31m sa \033[0m:安装samba服务端                                               #
#	输入 \033[31m sq \033[0m:安装squid                                                     #
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\033[31m监控\033[0m<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
#	输入 \033[31m f  \033[0m:安装filebeat(日志收集|仅限客户端)                             #
#	输入 \033[31m za \033[0m:安装zabbix-agent(指标监控|仅限客户端)                         #
#	输入 \033[31m e  \033[0m:安装elastic(elasticsearch master|kibana|logstash) & JDK       #
#	输入 \033[31m em \033[0m:安装elasticsearch master & JDK                                #
#	输入 \033[31m en \033[0m:安装elasticsearch node & JDK                                  #
#	输入 \033[31m ki \033[0m:安装kibana & JDK                                              #
#	输入 \033[31m l  \033[0m:安装logstash & JDK                                            #
#	输入 \033[31m g  \033[0m:安装grafana                                                   #
#	输入 \033[31m z  \033[0m:安装zabbix-server|angent|proxy|get with nginx|mysql|php       #
#	输入 \033[31m a  \033[0m:安装ansible                                                   #
###安装前请确认仔细阅读说明,并核对安装根目录var_list内变量设置###################
###########################################################last version:20190122#
### mysql & nginx 监控平台公用，默认安装到平台目录###############################
"
	echo "请输入相应字母以选择安装:"
	read CHAR
	case $CHAR in
		p|P)
			plat_all_single
		;;
		pc|pC|Pc|PC)
			plat_all_cluster
		;;
		rk|Rk|rK|RK)
			plat_without_dscore
		;;
        d|D)
			palt_dscore	
		;;
        n|N)
			install_nginx
        ;;
        m|M)
			install_mysql
        ;;
        k|K)
			plat_kafka_single       
		;;
		kc|kC|Kc|KC)
			plat_kafka_cluster               
		;;
        nj|NJ|nJ|Nj)
			plat_node
		;;  
        r|R)
			install_redis
        ;;
        f|F)
			install_filebeat
        ;;
        za|zA|Za|ZA)
			install_zabbix_agent
        ;;
        sa|sA|Sa|SA)
			install_samba
        ;;
		sq|sQ|Sq|SQ)
			install_squid
        ;;
		e|E)
			monitor_elastic_all
		;;
        em|eM|Em|EM)
			monitor_elasticsearch_master
        ;;
        en|eN|En|EN)
			monitor_elasticsearch_node
        ;;
        ki|Ki|kI|KI)
			monitor_kibana
		;;
        l|L)
			monitor_logstash
		;;  
        G|g)
			monitor_grafana
        ;;
        z|Z)
			monitor_zabbix_server
        ;;
		a|A)
			monitor_ansible
        ;;
                xxx)
            install_php
        ;;
		*)
		echo "不支持的选项"
		;;
	esac
}
