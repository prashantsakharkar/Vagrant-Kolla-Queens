#!/bin/sh
echo "192.168.14.212	controller" > /etc/hosts
apt-get update
apt-get install python-pip -y
pip install -U pip
