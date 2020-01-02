#!/bin/sh
echo "10.10.10..213    controller" >> /etc/hosts
echo "172.172.3.202	controller" >> /etc/hosts
systemctl stop iscsid.socket
systemctl disable iscsid.socket
apt-get update
apt-get install python-pip -y
pip install -U pip
