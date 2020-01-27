#!/bin/sh
pvcreate /dev/vda
vgcreate cinder-volumes /dev/vda
echo "nameserver 172.172.3.1" >> /etc/resolve.conf
echo "nameserver 8.8.8.8" >> /etc/resolve.conf
mkdir /etc/kolla/config
pip install "kolla-ansible==9.0.0"
cp -r /usr/local/share/kolla-ansible/etc_examples/kolla /etc/kolla/
cp /usr/local/share/kolla-ansible/ansible/inventory/* .
mkdir /etc/kolla/certificates/
git clone https://github.com/prashantsakharkar/certs.git /etc/kolla/certificates/
git clone https://github.com/prashantsakharkar/keyrings.git /etc/kolla/config/
sed -e '/kolla_internal_vip_address/ s/^#*/#/' -i /etc/kolla/globals.yml
sed -i 's/1048576//g' /usr/local/share/kolla-ansible/ansible/roles/neutron/tasks/precheck.yml

echo "kolla_base_distro: "ubuntu"
kolla_install_type: "binary"
openstack_release: "train"
kolla_internal_vip_address: "10.10.10.214"
kolla_external_vip_address: "172.172.3.203"
kolla_external_fqdn: "kollaautoqueen.triliodata.demo"
kolla_enable_tls_external: "yes"
kolla_external_fqdn_cert: "/etc/kolla/certificates/tvm.cert.pem"
kolla_external_fqdn_cacert: "/etc/kolla/certificates/tvm.cert.pem"
network_interface: "eth2"
neutron_external_interface: "eth3"
keepalived_virtual_router_id: "95"
openstack_region_name: "USWEST"
enable_horizon: "yes"
enable_haproxy: "yes"
enable_ceph: "no"
cinder_backend_ceph: "yes"
cinder_volume_group: "cinder-volumes"
enable_cinder_backend_lvm: "yes"
enable_cinder: "yes"" >> /etc/kolla/globals.yml

kolla-genpwd

secret=`cat /etc/kolla/passwords.yml | grep cinder_rbd | awk -F ' ' '{print $2}'`
sed  -i '/rbd_secret_uuid/c rbd_secret_uuid = '$secret /etc/kolla/config/cinder/cinder-volume.conf

kolla-ansible -i /home/vagrant/all-in-one bootstrap-servers -vvv

kolla-ansible -i /home/vagrant/all-in-one prechecks -vvv

kolla-ansible -i /home/vagrant/all-in-one deploy -vvv

kolla-ansible post-deploy

pip install python-openstackclient python-glanceclient python-neutronclient
