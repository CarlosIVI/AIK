#!/bin/bash
sudo yum update -y
sudo yum install -y git 
#Clone salt repo
mkdir -p /srv/app
sudo chmod 777 /srv/app
git clone https://github.com/CarlosIVI/AIK /srv/app
#install salt
sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest.el7.noarch.rpm
sudo yum clean expire-cache;sudo yum -y install salt-minion; chkconfig salt-minion off
#config roles name
sudo cp -r /srv/app/conf/minion.d /etc/salt/
echo -e 'grains:\n roles:\n - aik' > /etc/salt/minion.d/grains.conf
sudo salt-call state.apply > ~/call.log