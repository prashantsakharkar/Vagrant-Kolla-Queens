#!/bin/bash -x

source /etc/kolla/admin-openrc.sh

#cloud admin resources
openstack domain create --enable --description cloud-admin-domain clouddomain

openstack user create --domain clouddomain --email trilio.build@trilio.io --password password --description cloud-admin-user --enable cloudadmin

openstack project create --domain clouddomain --description cloud-domain-project --enable cloudproject

openstack role add --domain clouddomain --user cloudadmin admin
openstack role add --project cloudproject --user cloudadmin admin

#Test resources
openstack domain create --enable --description trilio-test-domain trilio-test-domain

openstack user create --domain trilio-test-domain --email trilio.build@trilio.io --password password --description trilio-test-user --enable trilio-test-user

openstack user create --domain trilio-test-domain --email trilio.build@trilio.io --password password --description trilio-test-user --enable trilio-admin-user

openstack project create --domain trilio-test-domain --description trilio-test-project-1 --enable trilio-test-project-1
openstack project create --domain trilio-test-domain --description trilio-test-project-2 --enable trilio-test-project-2
openstack quota set --backups 100 --cores 100 --instances 100 --snapshots 100 --volumes 100 --secgroups 100 --secgroup-rules 1000 trilio-test-project-1
 openstack quota set --backups 100 --cores 100 --instances 100 --snapshots 100 --volumes 100 --secgroups 100 --secgroup-rules 1000 trilio-test-project-2

openstack role add --domain default --user admin admin
openstack role add --user trilio-admin-user --project trilio-test-project-1 admin
openstack role add --user trilio-admin-user --project trilio-test-project-1 _member_
openstack role add --user trilio-admin-user --project trilio-test-project-2 admin
openstack role add --user trilio-admin-user --project trilio-test-project-2 _member_
openstack role add --user trilio-test-user --project trilio-test-project-1 _member_
openstack role add --user trilio-test-user --project trilio-test-project-2 _member_
openstack role add --user trilio-test-user --domain trilio-test-domain admin

openstack network create --enable --project trilio-test-project-1 --internal trilio-internal-network
openstack subnet create --project trilio-test-project-1 --subnet-range 25.25.1.0/24 --ip-version 4 --network trilio-internal-network trilio-internal-subnet

openstack network create --enable --share --external public_network
openstack subnet create --gateway 192.168.1.1 --ip-version 4 --network public_network --allocation-pool start=192.168.40.5,end=192.168.40.10 --dhcp --subnet-range 192.168.0.0/16 public_subnet

wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create cirros --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public

openstack volume type create --public --property volume_backend_name=lvm-1 lvm

openstack flavor create --ram 64 --disk 1 --vcpus 1 tiny

chown root:root /opt/file-manager/tvault-recoverymanager-2.3.2.qcow2.gz
gunzip /opt/file-manager/tvault-recoverymanager-2.3.2.qcow2.gz
openstack image create fvm --file /opt/file-manager/tvault-recoverymanager-2.3.2.qcow2 --disk-format qcow2 --container-format bare --public
openstack image set --property hw_qemu_guest_agent=yes fvm

def_secgrp_id=`(openstack security group list --project trilio-test-project-1 | awk -F'|' '!/^(+--)|ID|aki|ari/ { print $2 }')`
echo $def_secgrp_id
openstack security group show $def_secgrp_id
openstack security group rule create --ethertype IPv4 --ingress --protocol tcp --dst-port 1:65535 $def_secgrp_id
openstack security group rule create --ethertype IPv4 --egress --protocol tcp --dst-port 1:65535 $def_secgrp_id
openstack security group rule create --ethertype IPv4 --ingress --protocol icmp $def_secgrp_id
openstack security group rule create --ethertype IPv4 --egress --protocol icmp $def_secgrp_id

#Enable multidomain for Horizon
sed -i '/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = /c OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True' /etc/kolla/horizon/local_settings
docker stop horizon
docker start horizon
sleep 10s

#Enable cloud admin
service_tenant_id=`(openstack project list | grep service | awk -F'|' '!/^(+--)|ID|aki|ari/ { print $2 }'| awk '{$1=$1;print}')`
cloudadmin_domain_id=`(openstack domain list | grep clouddomain | awk -F'|' '!/^(+--)|ID|aki|ari/ {print $2}' | awk '{$1=$1;print}')`
cloud_project_id=`(openstack project list | grep cloudproject | awk -F'|' '!/^(+--)|ID|aki|ari/ {print $2}' | awk '{$1=$1;print}')`

#Create cloudrc file on openstack at /etc/kolla/ directory
echo "export OS_AUTH_URL=$OS_AUTH_URL
export OS_PROJECT_ID=$cloud_project_id
export OS_PROJECT_NAME=cloudproject
export OS_USER_DOMAIN_NAME=clouddomain
export OS_PROJECT_DOMAIN_ID=$cloudadmin_domain_id
export OS_PROJECT_DOMAIN_NAME=clouddomain
unset OS_TENANT_ID
unset OS_TENANT_NAME
export OS_USERNAME=cloudadmin
export OS_REGION_NAME=$OS_REGION_NAME
export OS_INTERFACE=$OS_INTERFACE
export OS_IDENTITY_API_VERSION=$OS_IDENTITY_API_VERSION
export OS_PASSWORD=password
export OS_INSECURE='true'
export OS_VERIFY='false'" >> /etc/kolla/cloudrc
