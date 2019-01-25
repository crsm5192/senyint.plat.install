#!/bin/bash

#start
echo "`date +%F\ %T` 开始安装squid"

#squid_user_check
id ${SQ_USER} &>/dev/null
if [ $? = 1 ];then
	groupadd -g 23 ${SQ_USER} 1>/dev/null
        useradd -g ${SQ_USER} -u 23 ${SQ_USER} -s /sbin/nologin 1>/dev/null
fi
	
#squid_install_path
mkdir -p ${PLAT_HOME}/squid/run
mkdir -p ${PLAT_HOME}/squid/var
mkdir -p ${PLAT_HOME}/squid/run
mkdir -p ${PLAT_HOME}/squid/log
mkdir -p ${PLAT_HOME}/squid/etc

#squid_install_squid
SQ_SOURCE=`ls ${INSTALL_DIR}/source |grep squid`
tar zxvf ${INSTALL_DIR}/source/$SQ_SOURCE -C $INSTALL_DIR/tmp 1>/dev/null
SQ_PATH=`ls ${INSTALL_DIR}/tmp |grep squid`
SQ_PATH=${INSTALL_DIR}/tmp/$SQ_PATH
pushd $SQ_PATH &>/dev/null
	./configure \
		--prefix=${PLAT_HOME}/squid \
		--sysconfdir=${PLAT_HOME}/squid/etc \
		--enable-dlmalloc=${JEMALLOC_PATH}/lib \
		--with-default-user=${SQ_USER} \
		--with-logdir=${PLAT_HOME}/squid/log/squid \
		--with-pidfile=${PLAT_HOME}/squid/run/squid.pid \
		--localstatedir=${PLAT_HOME}/squid/var \
		--enable-xmalloc-debug \
		--enable-xmalloc-debug-trace \
		--enable-xmalloc-statistics \
		--enable-icmp \
		--enable-delay-pools \
		--enable-useragent-log \
		--enable-kill-parent-hack \
		--enable-linux-netfilter \
		--enable-linux-tproxy \
		--enable-htpc \
		--enable-cache-digests \
		--enable-async-io=240 \
		--enable-follow-x-forwarded-for \
		--with-large-files \
		--enable-err-language="Simplify_Chinese" \
		--enable-poll \
		--enable-underscore \
		--enable-gnuregex &>/dev/null
		[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make -j ${THREAD} &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make install &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"

#squid_install_conf
sed -i "s#http_port 3128#http_port 8092#g" ${PLAT_HOME}/squid/etc/squid.conf
chown -R ${SQ_USER}.${SQ_USER}  ${PLAT_HOME}/squid

#squid_install_service
cat > /lib/systemd/system/squid.service<<SQSER
## Copyright (C) 1996-2018 The Squid Software Foundation and contributors
## Squid software is distributed under GPLv2+ license and includes
## contributions from numerous individuals and organizations.
## Please see the COPYING and CONTRIBUTORS files for details.
[Unit]
Description=Squid Web Proxy Server
Documentation=man:squid(8)
After=network.target network-online.target nss-lookup.target
[Service]
Type=forking
User=${SQ_USER}
Group=${SQ_USER}
PIDFile=${PLAT_HOME}/squid/run/squid.pid
ExecStartPre=${PLAT_HOME}/squid/sbin/squid --foreground -z
ExecStart=${PLAT_HOME}/squid/sbin/squid -sYC
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
[Install]
WantedBy=multi-user.target
#squid_install_firewall
SQSER
chmod +x /usr/lib/systemd/system/squid.service
systemctl daemon-reload 
systemctl start squid 
systemctl enable squid.service 

#squid_install_firewall
firewall-cmd --zone=public --add-port=$SQ_PORT/tcp --permanent
firewall-cmd --reload
