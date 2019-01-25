#!/bin/bash

#start
TART_T=`date +%s` &>/dev/null
echo "`date +%F\ %T` 开始安装php"

#php_install_path
mkdir -p ${PLAT_HOME}/php/tmp
mkdir -p ${PLAT_HOME}/php/log
mkdir -p ${PLAT_HOME}/php/run

#	--with-ldap \
#php_install_PHP
PHP_SOURCE=`ls ${INSTALL_DIR}/source |grep php`
tar zxvf ${INSTALL_DIR}/source/$PHP_SOURCE -C $INSTALL_DIR/tmp 1>/dev/null
PHP_PATH=`ls ${INSTALL_DIR}/tmp |grep php`
PHP_PATH=${INSTALL_DIR}/tmp/$PHP_PATH
pushd ${PHP_PATH} &>/dev/null
./configure --prefix=${PLAT_HOME}/php \
	--with-config-file-path=${PLAT_HOME}/php/etc \
	--with-config-file-scan-dir=${PLAT_HOME}/php/etc/php.d \
	--with-mcrypt=/usr/include \
	--enable-mysqlnd \
	--with-mysqli \
	--with-pdo-mysql \
	--enable-fpm \
	--with-fpm-user=${NGX_USER} \
	--with-fpm-group=${NGX_USER} \
	--with-gd \
	--with-iconv \
	--with-zlib \
	--enable-xml \
	--enable-shmop \
	--enable-sysvsem \
	--without-libzip \
	--enable-inline-optimization \
	--enable-mbregex \
	--enable-mbstring \
	--enable-ftp \
	--enable-gd-native-ttf \
	--with-openssl \
	--enable-pcntl \
	--enable-sockets \
	--with-xmlrpc \
	--enable-zip \
	--enable-soap \
	--without-pear \
	--with-gettext \
	--enable-session \
	--with-curl \
	--with-jpeg-dir \
	--with-freetype-dir \
	--enable-opcache \
	--disable-fileinfo \
	--with-png-dir \
	--with-libxml-dir=/usr/include/libxml2/libxml \
	--disable-rpath \
	--enable-bcmath \
	--enable-exif \
	--with-xsl \
	--with-mhash \
	--enable-intl &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make -j ${THREAD} &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make install &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"

#php_install_bin
ln -sf ${PLAT_HOME}/php/bin/php /usr/bin/php
ln -sf ${PLAT_HOME}/php/bin/phpize /usr/bin/phpize
ln -sf ${PLAT_HOME}/php/sbin/php-fpm /usr/bin/php-fpm

#php_install_conf
echo "`date +%F\ %T` 配置php配置文件"
cp ${PHP_PATH}/php.ini-production ${PLAT_HOME}/php/etc/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/g' ${PLAT_HOME}/php/etc/php.ini
sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${PLAT_HOME}/php/etc/php.ini
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${PLAT_HOME}/php/etc/php.ini
sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${PLAT_HOME}/php/etc/php.ini
sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${PLAT_HOME}/php/etc/php.ini
sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' ${PLAT_HOME}/php/etc/php.ini
sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${PLAT_HOME}/php/etc/php.ini
sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server/g' ${PLAT_HOME}/php/etc/php.ini
cat > ${PLAT_HOME}/php/etc/php-fpm.conf<<EOF
[global]
pid = ${PLAT_HOME}/php/run/php-fpm.pid
error_log = ${PLAT_HOME}/php/log/php-fpm.log
log_level = notice

[www]
listen = ${PLAT_HOME}/php/tmp/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = ${NGX_USER}
listen.group = ${NGX_USER}
listen.mode = 0666
user = ${NGX_USER}
group = ${NGX_USER}
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = ${PLAT_HOME}/php/log/slow.log
EOF

cat > ${PLAT_HOME}/nginx/conf/enable-php.conf<<nginx_php
		location ~ [^/]\.php(/|$)
		{
			fastcgi_pass  unix:${PLAT_HOME}/php/tmp/php-cgi.sock;
			fastcgi_index index.php;
			include fastcgi.conf;
		}
nginx_php

#php_mem_conf
if [[ ${MEM} -gt 1024 && ${MEM} -le 2048 ]]; then
	sed -i "s#pm.max_children.*#pm.max_children = 20#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.start_servers.*#pm.start_servers = 10#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 10#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 20#" ${PLAT_HOME}/php/etc/php-fpm.conf
elif [[ ${MEM} -gt 2048 && ${MEM} -le 4096 ]]; then
	sed -i "s#pm.max_children.*#pm.max_children = 40#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.start_servers.*#pm.start_servers = 20#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 20#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 40#" ${PLAT_HOME}/php/etc/php-fpm.conf
elif [[ ${MEM} -gt 4096 && ${MEM} -le 8192 ]]; then
	sed -i "s#pm.max_children.*#pm.max_children = 60#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.start_servers.*#pm.start_servers = 30#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 30#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 60#" ${PLAT_HOME}/php/etc/php-fpm.conf
elif [[ ${MEM} -gt 8192 ]]; then
	sed -i "s#pm.max_children.*#pm.max_children = 80#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.start_servers.*#pm.start_servers = 40#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 40#" ${PLAT_HOME}/php/etc/php-fpm.conf
	sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 80#" ${PLAT_HOME}/php/etc/php-fpm.conf
fi

#php_install_service
echo "`date +%F\ %T` 配置php系统服务"
cp ${PHP_PATH}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
cp ${PHP_PATH}/sapi/fpm/php-fpm.service /lib/systemd/system/php-fpm.service
systemctl daemon-reload
systemctl enable php-fpm.service
systemctl start php-fpm

#end
export PHP_PATH=${PLAT_HOME}/php
echo "`date +%F\ %T` php安装完成，安装目录${PHP_PATH}"

























    
