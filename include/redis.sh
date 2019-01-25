#!/bin/sh

#start
echo "`date +%F\ %T` 开始安装redis"

#redis_install_path
mkdir -p ${PLAT_HOME}/redis
mkdir -p ${PLAT_HOME}/redis/data
mkdir -p ${PLAT_HOME}/redis/etc
mkdir -p ${PLAT_HOME}/redis/bin 
mkdir -p ${PLAT_HOME}/redis/pid
mkdir -p ${PLAT_HOME}/redis/log

#redis_install_redis
REDIS_SOURCE=`ls ${INSTALL_DIR}/source | grep redis`
tar zxvf $INSTALL_DIR/source/${REDIS_SOURCE} -C $INSTALL_DIR/tmp 1>/dev/null
REDIS_PATH=`ls ${INSTALL_DIR}/tmp |grep redis`
pushd ${INSTALL_DIR}/tmp/${REDIS_PATH} &>/dev/null
make -j ${THREAD} &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make -j ${THREAD} test &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
pushd src &>/dev/null
make install &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"

#redis_install_bin
cp ${INSTALL_DIR}/tmp/${REDIS_PATH}/src/{redis-benchmark,redis-check-aof,redis-check-rdb,redis-cli,redis-sentinel,redis-server} ${PLAT_HOME}/redis/bin
export REDIS_PATH=${PLAT_HOME}/redis
ln -sf ${REDIS_PATH}/bin/redis-cli /usr/bin/redis-cli

#redis_install_conf
cat > ${REDIS_PATH}/etc/redis.conf<<REDISCONF
bind 0.0.0.0
protected-mode yes
port ${REDIS_PORT}
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize yes
supervised no
pidfile ${REDIS_PATH}/pid/redis_${REDIS_PORT}.pid
loglevel notice
logfile ${REDIS_PATH}/log/redis.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir ${REDIS_PATH}/data
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
requirepass ${REDIS_PASSWD}
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes
REDISCONF
chown -R ${PLAT_USER}.${PLAT_USER} ${REDIS_PATH}

#redis_install_service
cat > /lib/systemd/system/redis-server.service<<REDISSRV
[Unit]
Description=Redis In-Memory Data Store
After=network.target
[Service]
Type=forking
PIDFile=${REDIS_PATH}/pid/redis_${REDIS_PORT}.pid
User=${PLAT_USER}
Group=${PLAT_USER}
ExecStart=${REDIS_PATH}/bin/redis-server ${REDIS_PATH}/etc/redis.conf
ExecStop=${REDIS_PATH}/bin/redis-cli -a ${REDIS_PASSWD} shutdown
Restart=always
[Install]
WantedBy=multi-user.target
REDISSRV
chmod +x /lib/systemd/system/redis-server.service
systemctl daemon-reload 
systemctl start redis-server 
systemctl enable redis-server.service

#redis_install_firewall
firewall-cmd --zone=public --add-port=${REDIS_PORT}/tcp --permanent
firewall-cmd --reload

#redis_bakup
cp -rf ${INSTALL_DIR}/scripts/redis_db_backup.sh ${BAK_HOME}/scripts/
chmod +x ${BAK_HOME}/scripts/*
echo "30 1 * * * root /bin/bash /data/bakup/scripts/redis_db_backup.sh &>/dev/null" >> /etc/crontab

#end
echo "`date +%F\ %T` redis安装完成,redis目录${PLAT_HOME}/redis"