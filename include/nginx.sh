#!/bin/bash

#start
echo "`date +%F\ %T` 开始安装nginx"

#nginx user check
id ${NGX_USER} &>/dev/null
if [ $? = 1 ];then
	groupadd -g 8000 ${NGX_USER} 1>/dev/null
	useradd -g ${NGX_USER} -u 8000 ${NGX_USER} -s /sbin/nologin 1>/dev/null
fi

#nginx_install_pcre
echo "`date +%F\ %T` 安装pcre库"
PCRE_SOURCE=`ls ${INSTALL_DIR}/source | grep pcre`
tar zxvf $INSTALL_DIR/source/$PCRE_SOURCE -C ${INSTALL_DIR}/tmp 1>/dev/null
PCRE_PATH=`ls ${INSTALL_DIR}/tmp | grep pcre`
export PCRE_PATH=${INSTALL_DIR}/tmp/${PCRE_PATH}
#echo "`date +%F\ %T` pcre模块已安装至${PCRE_PATH}"

#nginx_install_zlib
echo "`date +%F\ %T` 安装zlib库"
ZLIB_SOURCE=`ls ${INSTALL_DIR}/source | grep zlib`
tar zxvf $INSTALL_DIR/source/$ZLIB_SOURCE -C ${INSTALL_DIR}/tmp 1>/dev/null
ZLIB_PATH=`ls ${INSTALL_DIR}/tmp | grep zlib`
export ZLIB_PATH=${INSTALL_DIR}/tmp/${ZLIB_PATH}
#echo "`date +%F\ %T` zlib模块已安装至${ZLIB_PATH}"

#nginx_install_openssl
echo "`date +%F\ %T` 安装openssl库"
OSSL_SOURCE=`ls ${INSTALL_DIR}/source | grep openssl`
tar zxvf $INSTALL_DIR/source/$OSSL_SOURCE -C ${INSTALL_DIR}/tmp 1>/dev/null
OSSL_PATH=`ls ${INSTALL_DIR}/tmp | grep openssl`
export OSSL_PATH=${INSTALL_DIR}/tmp/${OSSL_PATH}
#echo "`date +%F\ %T` openssl模块已安装至${OSSL_PATH}"

#nginx_install_ngx_devel_kit
echo "`date +%F\ %T` 安装ngx_devel_kit模块"
NgxDevelKit_SOURCE=`ls ${INSTALL_DIR}/source | grep ngx_devel_kit`
tar zxvf $INSTALL_DIR/source/$NgxDevelKit_SOURCE -C ${INSTALL_DIR}/tmp 1>/dev/null
NgxDevelKit_PATH=`ls ${INSTALL_DIR}/tmp | grep ngx_devel_kit`
export NgxDevelKit_PATH=${INSTALL_DIR}/tmp/${NgxDevelKit_PATH}
#echo "`date +%F\ %T` ngx_devel_kit模块已安装至${NgxDevelKit_PATH}"

#nginx_install_LuaNginxModule
echo "`date +%F\ %T` 安装LuaNginxModule模块"
LuaNginxModule_SOURCE=`ls ${INSTALL_DIR}/source | grep lua-nginx-module`
tar zxvf $INSTALL_DIR/source/$LuaNginxModule_SOURCE -C ${INSTALL_DIR}/tmp 1>/dev/null
LuaNginxModule_PATH=`ls ${INSTALL_DIR}/tmp | grep lua-nginx-module`
export LuaNginxModule_PATH=${INSTALL_DIR}/tmp/${LuaNginxModule_PATH}
#echo "`date +%F\ %T` LuaNginxModule模块已安装至${LuaNginxModule_PATH}"

#nginx_install_nginx
echo "`date +%F\ %T` 编译nginx"
NGINX_SOURCE=`ls ${INSTALL_DIR}/source | grep nginx-1` 
tar zxvf $INSTALL_DIR/source/$NGINX_SOURCE -C $INSTALL_DIR/tmp 1>/dev/null
NGX_PATH=`ls ${INSTALL_DIR}/tmp | grep nginx-1`
NGX_PATH=${INSTALL_DIR}/tmp/${NGX_PATH}
pushd ${NGX_PATH} &>/dev/null
	./configure --prefix=${PLAT_HOME}/nginx \
		--sbin-path=${PLAT_HOME}/nginx/sbin/nginx \
		--conf-path=${PLAT_HOME}/nginx/conf/nginx.conf \
		--error-log-path=${PLAT_HOME}/nginx/logs/error.log \
		--http-log-path=${PLAT_HOME}/nginx/logs/access.log \
		--pid-path=${PLAT_HOME}/nginx/nginx.pid  \
		--lock-path=${PLAT_HOME}/nginx/nginx.lock \
		--user=${NGX_USER} \
		--group=${NGX_USER} \
		--with-http_ssl_module \
		--with-http_v2_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_xslt_module \
		--with-http_stub_status_module \
		--with-http_sub_module \
		--with-http_random_index_module \
		--with-http_degradation_module \
		--with-http_secure_link_module \
		--with-http_gzip_static_module \
		--with-http_perl_module \
		--with-pcre=${PCRE_PATH} \
		--with-zlib=${ZLIB_PATH} \
		--with-openssl=${OSSL_PATH} \
		--with-debug \
		--with-file-aio \
		--with-mail \
		--with-ipv6 \
		--with-mail_ssl_module \
		--with-http_image_filter_module \
		--http-client-body-temp-path=${PLAT_HOME}/nginx/client_body \
		--http-proxy-temp-path=${PLAT_HOME}/nginx/proxy \
		--http-fastcgi-temp-path=${PLAT_HOME}/nginx/fastcgi \
		--http-uwsgi-temp-path=${PLAT_HOME}/nginx/uwsgi \
		--http-scgi-temp-path=${PLAT_HOME}/nginx/scgi \
		--with-stream \
		--with-ld-opt=-L${JEMALLOC_PATH}/lib \
		--with-ld-opt=-Wl,-rpath,${LuaJIT_PATH}/lib \
		--add-module=${NgxDevelKit_PATH} \
		--add-module=${LuaNginxModule_PATH} &>/dev/null
	[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make -j ${THREAD} &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
make install &>/dev/null
[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"

#nginx_install_conf
echo "`date +%F\ %T` 配置nginx文件"
mkdir -p ${PLAT_HOME}/nginx/conf/conf.d
mv ${PLAT_HOME}/nginx/conf/nginx.conf ${PLAT_HOME}/nginx/conf/nginx.confbak
cat > ${PLAT_HOME}/nginx/conf/nginx.conf<<ngx_conf
user  ${NGX_USER} ${NGX_USER};
worker_processes ${THREAD};
worker_rlimit_nofile 204800;
error_log  logs/error.log  warn;
pid        nginx.pid;

events
    {
        use epoll;
	multi_accept          on;
	accept_mutex         off;
        worker_connections 65535;
    }

http
    {
        include                     mime.types;		
        default_type  application/octet-stream;

        log_format json '{'
                    '"remote_ip": "\$remote_addr",'
                     '"@timestamp": "\$time_iso8601",'
                     '"request_method": "\$request_method",'
                     '"request_api": "\$uri",'
                     '"request_args": "\$args",'
                     '"request_status": "\$status",'
                     '"request_bytes": "\$body_bytes_sent",'
                     '"request_agent": "\$http_user_agent",'
                     '"referer": "\$http_referer",'
                     '"up_response_status": "\$upstream_status",'
                     '"upstream_server": "\$upstream_addr",'
                     '"up_request_time": "\$request_time",'
                     '"up_response_time": "\$upstream_response_time",'
                     '"plat_request_id": "\$sent_http_request_id",'
                     '"nginx_request_id": "\$request_id"'
	'}';		
		
	sendfile       on;
        tcp_nopush     on;
	tcp_nodelay    on;
	autoindex     off;
	server_tokens off;

	keepalive_timeout 300 300;
		
        server_names_hash_bucket_size       128;        
	send_timeout                         3m;
	uninitialized_variable_warn         off;
	chunked_transfer_encoding            on;
	open_file_cache_valid               30s;
	open_file_cache max=102400 inactive=20s;

	include conf.d/*.conf;
}

stream {
	upstream tcpbackend {
		hash $remote_addr consistent;
		server localhost:8016;
	}
	server {
		listen 8015;
		proxy_connect_timeout 900;
		proxy_timeout 3s;
		proxy_pass tcpbackend;
	}
}
ngx_conf

cp -rf ${INSTALL_DIR}/conf/proxy.conf ${PLAT_HOME}/nginx/conf/proxy.conf
cp -rf ${INSTALL_DIR}/conf/location.conf ${PLAT_HOME}/nginx/conf/location.conf
cp -rf ${INSTALL_DIR}/conf/client.conf ${PLAT_HOME}/nginx/conf/conf.d/client.conf
cp -rf ${INSTALL_DIR}/conf/fastcgi.conf ${PLAT_HOME}/nginx/conf/conf.d/fastcgi.conf
cp -rf ${INSTALL_DIR}/conf/gzip.conf ${PLAT_HOME}/nginx/conf/conf.d/gzip.conf
cp -rf ${INSTALL_DIR}/conf/map.conf ${PLAT_HOME}/nginx/conf/conf.d/map.conf
cp -rf ${INSTALL_DIR}/conf/443.conf ${PLAT_HOME}/nginx/conf/conf.d/443.conf
cp -rf ${INSTALL_DIR}/conf/8088.conf ${PLAT_HOME}/nginx/conf/conf.d/8088.conf
cp -rf ${INSTALL_DIR}/conf/upstream.conf ${PLAT_HOME}/nginx/conf/conf.d/upstream.conf
/bin/cp -rf  ${INSTALL_DIR}/conf/ssl ${PLAT_HOME}/nginx/conf/conf.d/ssl

#nginx_install_service
echo "`date +%F\ %T` 配置nginx系统服务"
cat > /lib/systemd/system/nginx.service<<ngx_service
[Unit]
Description=Nginx Server
After=network.target  
[Service]
Type=forking
ExecStart=${PLAT_HOME}/nginx/sbin/nginx
ExecReload=${PLAT_HOME}/nginx/sbin/nginx -s reload
ExecStop=${PLAT_HOME}/nginx/sbin/nginx -s quit
Restart=always
PrivateTmp=true 
[Install]
WantedBy=multi-user.target
ngx_service
chmod +x /lib/systemd/system/nginx.service
chown -R ${NGX_USER}.${NGX_USER} ${PLAT_HOME}/nginx
systemctl daemon-reload 
systemctl enable nginx.service 
systemctl start nginx 

#nginx_install_firewall
echo "`date +%F\ %T` 防火墙开放nginx端口"
firewall-cmd --zone=public --add-port=${NGX_PORT}/tcp --permanent
firewall-cmd --reload

#nginx_log_bakup
echo "`date +%F\ %T` 配置nginx日志日切脚本"
cp -rf ${INSTALL_DIR}/scripts/nginx_log_backup.sh ${BAK_HOME}/scripts/
chmod +x ${BAK_HOME}/scripts/*
echo "1 0 * * * root bin/bash ${BAK_HOME}/scripts/nginx_log_backup.sh &>/dev/null" >> /etc/crontab

#end
export NGX_PATH=${PLAT_HOME}/nginx
echo "`date +%F\ %T` nginx安装完成,nginx目录${NGX_PATH}"
