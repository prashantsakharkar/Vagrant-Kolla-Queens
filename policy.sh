#!/bin/bash -x

source /etc/kolla/admin-openrc.sh

mkdir /etc/kolla/config/keystone

git clone https://github.com/prashantsakharkar/policy.json.git /etc/kolla/config/keystone/

service_tenant_id=`(openstack project list | grep service | awk -F'|' '!/^(+--)|ID|aki|ari/ { print $2 }'| awk '{$1=$1;print}')`
cloudadmin_domain_id=`(openstack domain list | grep clouddomain | awk -F'|' '!/^(+--)|ID|aki|ari/ {print $2}' | awk '{$1=$1;print}')`
sudo sed -i '/cloud_admin":/c \    "cloud_admin": "rule:admin_required and (is_admin_project:True or domain_id:'$cloudadmin_domain_id' or project_id:'$service_tenant_id')",' /etc/kolla/config/keystone/policy.json

kolla-ansible -i /home/vagrant/all-in-one reconfigure -vv
