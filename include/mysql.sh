#!/bin/bash

#start
echo "`date +%F\ %T` 开始安装mysql"

#mysql_user_check
id ${MYSQL_USER} &>/dev/null
if [ $? = 1 ];then
	groupadd -g 3306 ${MYSQL_USER} 1>/dev/null
	useradd -g ${MYSQL_USER} -u 3306 ${MYSQL_USER} -s /sbin/nologin 1>/dev/null
fi

#mysql_old_remove
rm -f /etc/my.cnf
rm -f /root/.mysql_secret
#yum remove mariadb* -y >& /dev/null
	
#mysql_install_path
mkdir -p ${PLAT_HOME}/mysql
mkdir -p ${PLAT_HOME}/mysql/etc
mkdir -p ${PLAT_HOME}/mysql/data
mkdir -p ${PLAT_HOME}/mysql/pid
mkdir -p ${PLAT_HOME}/mysql/src
mkdir -p ${PLAT_HOME}/mysql/log
mkdir -p ${PLAT_HOME}/mysql/binlog
mkdir -p ${PLAT_HOME}/mysql/sock
chown -R ${MYSQL_USER}.${MYSQL_USER} ${PLAT_HOME}/mysql

#mysql_install_mysql
MYSQL_SOURCE=`ls ${INSTALL_DIR}/source |grep mysql`
tar zxvf ${INSTALL_DIR}/source/$MYSQL_SOURCE -C $INSTALL_DIR/tmp 1>/dev/null
MYSQL_PATH=`ls ${INSTALL_DIR}/tmp |grep mysql`
MYSQL_PATH=${INSTALL_DIR}/tmp/$MYSQL_PATH
pushd $MYSQL_PATH &>/dev/null
	cmake . \
		-DCMAKE_INSTALL_PREFIX=${PLAT_HOME}/mysql/src \
        -DMYSQL_DATADIR=${PLAT_HOME}/mysql/data \
        -DSYSCONFDIR=${PLAT_HOME}/mysql/etc \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 \
		-DWITH_MEMORY_STORAGE_ENGINE=1 \
        -DWITH_PARTITION_STORAGE_ENGINE=1 \
        -DWITH_FEDERATED_STORAGE_ENGINE=1 \
        -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
        -DWITH_MYISAM_STORAGE_ENGINE=1 \
		-DMYSQL_UNIX_ADDR=${PLAT_HOME}/mysql/sock/mysql.sock \
        -DCMAKE_EXE_LINKER_FLAGS="-L ${JEMALLOC_PATH}/lib -ljemalloc" \
        -DWITH_SAFEMALLOC=OFF \
		-DWITH_DEBUG=0 \
        -DENABLED_LOCAL_INFILE=1 \
        -DENABLE_DTRACE=0 \
		-DENABLE_PROFILING=1 \
		-DEXTRA_CHARSETS=all \
        -DDEFAULT_CHARSET=utf8mb4 \
        -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DWITH_EMBEDDED_SERVE=1 &>/dev/null
	[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
	make -j ${THREAD} &>/dev/null
	[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
	make install &>/dev/null
	[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"

#mysql_install_conf
echo "`date +%F\ %T` 配置mysql配置文件"
cat > ${PLAT_HOME}/mysql/etc/my.cnf<<mysql_conf
[client]
default-character-set          = utf8
socket                         = ${PLAT_HOME}/mysql/sock/mysql.sock
[mysqld]
user                           = ${MYSQL_USER}
symbolic-links                 = 0
lower_case_table_names         = 1
back_log                       = -1
max_connections                = 500
max_allowed_packet             = 32M
log-bin                        = ${PLAT_HOME}/mysql/binlog/mysql-bin
binlog-format                  = 'mixed'
binlog_cache_size              = 1M
max_heap_table_size            = 64M
read_buffer_size               = 16M
read_rnd_buffer_size           = 64M
sort_buffer_size               = 32M
join_buffer_size               = 32M
thread_cache_size              = 32
thread_concurrency             = 16
query_cache_size               = 128M
query_cache_limit              = 32M
tmp_table_size                 = 1024M
table_open_cache               = 2048
key_buffer_size                = 256M
bulk_insert_buffer_size        = 256M
myisam_sort_buffer_size        = 128M
myisam_max_sort_file_size      = 10G
myisam_repair_threads          = 1
myisam_recover
innodb_buffer_pool_size        = 100M
innodb_buffer_pool_instances   = 16
innodb_write_io_threads        = 8
innodb_read_io_threads         = 8
innodb_file_per_table          = 1
innodb_thread_concurrency      = 16
innodb_flush_log_at_trx_commit = 2
innodb_log_file_size           = 3G
innodb_flush_method            = O_DIRECT
innodb_lock_wait_timeout       = 120
datadir                        = ${PLAT_HOME}/mysql/data
socket                         = ${PLAT_HOME}/mysql/sock/mysql.sock
symbolic-links                 = 0
sql_mode                       = NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES 
character-set-server           = utf8
collation-server               = utf8_general_ci
connect_timeout                = 600
port                           = ${MYSQL_PORT}
[mysqldump]
quick
max_allowed_packet             = 32M
[mysqld_safe]
log-error                      = ${PLAT_HOME}/mysql/log/mysql.log
pid-file                       = ${PLAT_HOME}/mysql/pid/mysqld.pid
mysql_conf

#mysql_install_db
echo "`date +%F\ %T` 初始化mysql数据库"
touch ${PLAT_HOME}/mysql/log/mysql.log
pushd ${PLAT_HOME}/mysql/src/scripts &>/dev/null
./mysql_install_db --user=${MYSQL_USER} --basedir=${PLAT_HOME}/mysql/src --datadir=${PLAT_HOME}/mysql/data 1>/dev/null

#mysql_install_bin
ln -s ${PLAT_HOME}/mysql/src/bin/mysql /usr/bin/mysql
ln -s ${PLAT_HOME}/mysql/src/bin/mysqladmin /usr/bin/mysqladmin
ln -s ${PLAT_HOME}/mysql/src/bin/mysqldump /usr/bin/mysqldump

#mysql_install_service
echo "`date +%F\ %T` 配置mysql系统服务"
cp -rf  ${PLAT_HOME}/mysql/src/support-files/mysql.server /etc/init.d/mysqld
chown -R ${MYSQL_USER}.${MYSQL_USER} ${PLAT_HOME}/mysql
sed -i "s@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=${JEMALLOC_PATH}/lib/libjemalloc.so@" ${PLAT_HOME}/mysql/src/bin/mysqld_safe	

cat > /lib/systemd/system/mysqld.service<<mysql_service
[Unit]
Description=MySQL Server
After=network.target
[Service]
Type=forking
ExecStart=/etc/init.d/mysqld start
ExecStop=/etc/init.d/mysqld stop
Restart=always
PrivateTmp=true
[Install]
WantedBy=multi-user.target
mysql_service
systemctl daemon-reload 
systemctl start mysqld 
systemctl enable mysqld.service

#mysql_install_firewall
echo "`date +%F\ %T`防火墙开放mysql端口"
firewall-cmd --zone=public --add-port=${MYSQL_PORT}/tcp --permanent
firewall-cmd --reload

#mysql_install_grant
echo "`date +%F\ %T`修改root用户初始密码"
mysql -uroot -e \
	"CREATE USER '${PLAT_DB_USER}'@'%' IDENTIFIED BY '${PLAT_DB_PASSWD}'; \
	GRANT ALL PRIVILEGES ON *.* TO '${PLAT_DB_USER}'@'%' \
	IDENTIFIED BY '${PLAT_DB_PASSWD}' WITH GRANT OPTION; \
	GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' \
	IDENTIFIED BY '${MYSQL_PASSWD}' WITH GRANT OPTION; \
	GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' \
	IDENTIFIED BY '${MYSQL_PASSWD}' WITH GRANT OPTION; \
	flush privileges;"
				
#mysql_bakup
echo "`date +%F\ %T`添加mysql数据库备份脚本"
cp -rf ${INSTALL_DIR}/scripts/mysql_db_backup.sh ${BAK_HOME}/scripts/
chmod +x ${BAK_HOME}/scripts/*
echo "0 1 * * * root /bin/bash ${BAK_HOME}/scripts/mysql_db_backup.sh &>/dev/null" >> /etc/crontab

#end
export MYSQL_PATH=${PLAT_HOME}/mysql
echo "`date +%F\ %T` mysql安装完成,mysql目录${MYSQL_PATH}"
