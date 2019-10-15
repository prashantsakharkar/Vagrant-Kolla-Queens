#!/bin/sh
pvcreate /dev/vda
vgcreate cinder-volumes /dev/vda
echo "nameserver 8.8.8.8" >> /etc/resolve.conf
pip install "kolla-ansible==6.2.1"
cp -r /usr/local/share/kolla-ansible/etc_examples/kolla /etc/kolla/
cp /usr/local/share/kolla-ansible/ansible/inventory/* .
sed -e '/kolla_internal_vip_address/ s/^#*/#/' -i /etc/kolla/globals.yml
sed -i 's/1048576//g' /usr/local/share/kolla-ansible/ansible/roles/neutron/tasks/precheck.yml

echo "kolla_base_distro: "ubuntu"
kolla_install_type: "binary"
openstack_release: "queens"
kolla_internal_vip_address: "192.168.14.212"
network_interface: "eth1"
neutron_external_interface: "eth2"
openstack_region_name: "USWEST"
enable_horizon: "yes"
enable_haproxy: "no"
enable_cinder_backend_lvm: "yes"
enable_cinder: "yes"" >> /etc/kolla/globals.yml

kolla-genpwd

kolla-ansible -i /home/vagrant/all-in-one prechecks -vvv

kolla-ansible -i /home/vagrant/all-in-one deploy -vvv

kolla-ansible post-deploy

pip install python-openstackclient python-glanceclient python-neutronclient
