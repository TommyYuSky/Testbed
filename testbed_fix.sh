#!/bin/sh

ulimit -n 999999

BASE_DIR = /testbed
SRC_DIR = /testbed/src

echo "Install the openvswtich manually"
if [ ! -e $BASE_DIR ]
then
    mkdir $BASE_DIR
    chmod 777 $BASE_DIR
fi

if [ ! -e $SRC_DIR ]
then
    mkdir $SRC_DIR
    chmod 777 $SRC_DIR
fi
cd $SRC_DIR

cp  /users/toby/src/openvswitch-2.3.0.tar.gz .
gzip -dc openvswitch-2.3.0.tar.gz | tar xvf -
cd openvswitch-2.3.0
./boot.sh
./configure --with-linux=/lib/modules/`uname -r`/build
make
make install
make modules_install
/sbin/modprobe openvswitch
/sbin/lsmod | grep -i openvswitch
/sbin/lsmod | grep -i openvswitch

mkdir -p /usr/local/etc/openvswitch
ovsdb-tool create /usr/local/etc/openvswitch/conf.db /usr/local/share/openvswitch/vswitch.ovsschema
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
                         --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
                                              --private-key=db:Open_vSwitch,SSL,private_key \
                                                                   --certificate=db:Open_vSwitch,SSL,certificate \
                                                                                        --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert \
                                                                                                             --pidfile --detach
ovs-vsctl --no-wait init
ovs-vswitchd --pidfile --detach
ovs-vsctl show
ovs-vsctl add-br br0

service apparmor teardown
service apparmor stop
service apparmor status
service libvirt-bin restart
