#!/bin/bash -x

source /etc/kolla/admin-openrc.sh
openstack domain create --enable --description trilio-test-domain trilio-test-domain

openstack user create --domain trilio-test-domain --email trilio.build@trilio.io --password password --description trilio-test-user --enable trilio-test-user

openstack project create --domain trilio-test-domain --description trilio-test-project-1 --enable trilio-test-project-1

openstack project create --domain trilio-test-domain --description trilio-test-project-2 --enable trilio-test-project-2

openstack role add --user trilio-test-user --project trilio-test-project-1 admin

openstack role add --user trilio-test-user --project trilio-test-project-1 _member_

openstack role add --user trilio-test-user --project trilio-test-project-2 admin

openstack role add --user trilio-test-user --project trilio-test-project-2 _member_

openstack role add --user trilio-test-user --domain trilio-test-domain admin

wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

openstack image create cirros --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public

openstack volume type create --public lvm

openstack flavor create --ram 64 --disk 1 --vcpus 1 tiny
