#!/bin/sh

#start
echo "`date +%F\ %T` 开始安装ansible"

#ansible_install_path
mkdir -p /etc/ansible
mkdir -p ${MON_HOME}/ansible/etc

#ansible_install_ansible
tar zxvf ${INSTALL_DIR}/source/ansible*.tar.gz -C ${INSTALL_DIR}/tmp >/dev/null
pushd ${INSTALL_DIR}/tmp/ansible* &>/dev/null
python setup.py install 1>/dev/null

#ansible_install_conf
/bin/cp -rf ${INSTALL_DIR}/conf/ansible/* ${MON_HOME}/ansible/etc
ln -sf  ${MON_HOME}/ansible/etc/* /etc/ansible/





