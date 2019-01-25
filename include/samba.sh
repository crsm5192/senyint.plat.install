#!/bin/bash

#prepare
samba_install_prepare(){
	#start
	echo "`date +%F\ %T` 开始安装samba"

	#samba_path
	mkdir -p ${SMB_DIR}
	chown -R ${SMB_USER}.${SMB_USER} ${SMB_DIR}
}


#server

samba_install_server(){
	yum remove -y samba* &>/dev/null
	export SMB_PATH=${PLAT_HOME}/samba
	mkdir -p ${SMB_PATH}/log
	tar zxvf  ${INSTALL_DIR}/source/samba*.tar.gz -C ${INSTALL_DIR}/tmp 1>/dev/null
	pushd ${INSTALL_DIR}/tmp/samba* &>/dev/null
		./configure \
			--prefix=${PLAT_HOME}/samba \
			--systemd-install-services &>/dev/null
			[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
	make -j ${THREAD} &>/dev/null
	[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
	make install &>/dev/null
	[ $? -ne 0 ] && echo "编译完成，但存在警告，请检查应用功能或重新编译。"
	
	
	#samba_install_conf
	cat > ${SMB_PATH}/etc/smb.conf<<smb_conf
[global]
        workgroup = ${SMB_WORK}
        unix charset = utf8
        security = user	
        log file = ${SMB_PATH}/log/smb_log.%m
        max log size = 50
        load printers = No
[${SMB_WORK}]
        comment = ${SMB_WORK}
        path = ${SMB_DIR}
        read only = No
        writable = yes
        create mask = 0775
        directory mask = 0775
        available = yes
        browseable = yes
		force user = ${SMB_USER}
		force group = ${SMB_USER}
smb_conf
	echo -e "${SMB_PWD}\n${SMB_PWD}" |/home/plat/samba/bin/smbpasswd -a ${SMB_USER}
	#samba_install_service
	chmod +x ${SMB_PATH}/lib/systemd/system/*
	/bin/cp -rf ${SMB_PATH}/lib/systemd/system/* /lib/systemd/system/
	systemctl daemon-reload 
	systemctl enable smb.service
	systemctl start smb 

	#samba_install_firewall
	firewall-cmd --zone=public --add-port=${SMB_PORT}/tcp --permanent
	firewall-cmd --reload
}

#client
samba_install_client(){
	mount.cifs //${SMB_IP}/${SMB_WORK} ${SMB_DIR} -o uid=8080,user=${SMB_USER},pass=${SMB_PWD}
	echo "//${SMB_IP}/${SMB_WORK}    ${SMB_DIR}     cifs     defaults,uid=8080,username=${SMB_USER},password=${SMB_PWD}   0 0" >> /etc/fstab
}

