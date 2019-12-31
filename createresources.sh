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

wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create cirros --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public

openstack volume type create --public --property volume_backend_name=lvm-1 lvm

openstack flavor create --ram 64 --disk 1 --vcpus 1 tiny

#scp root@192.168.1.20:/mnt/build-vault/file-manager/tvault-recoverymanager-2.3.2.qcow2.gz .
#gunzip tvault-recoverymanager-2.3.2.qcow2.gz
#openstack image create fvm --file tvault-recoverymanager-2.3.2.qcow2 --disk-format qcow2 --container-format bare --public
#openstack image set --property hw_qemu_guest_agent=yes fvm

def_secgrp_id=`(openstack security group list --project trilio-test-project-1 | awk -F'|' '!/^(+--)|ID|aki|ari/ { print $2 }')`
echo $def_secgrp_id
openstack security group show $def_secgrp_id
openstack security group rule create --ethertype IPv4 --ingress --protocol tcp --dst-port 1:65535 $def_secgrp_id
openstack security group rule create --ethertype IPv4 --egress --protocol tcp --dst-port 1:65535 $def_secgrp_id
openstack security group rule create --ethertype IPv4 --ingress --protocol icmp $def_secgrp_id
openstack security group rule create --ethertype IPv4 --egress --protocol icmp $def_secgrp_id

