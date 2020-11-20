 #!/bin/bash
sudo yum update -y
sudo yum install -y git 
#Clone salt repo
mkdir -p /srv/app
sudo chmod 777 /srv/app
git clone https://github.com/CarlosIVI/AIK /srv/app
#Install Salstack
sudo yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-latest.el7.noarch.rpm
sudo yum clean expire-cache;sudo yum -y install salt-minion; chkconfig salt-minion off
#Put custom minion config in place (for enabling masterless mode)
sudo cp -r /srv/app/configuration_management/minion.d /etc/salt/
echo -e 'grains:\n roles:\n  - frontend' > /etc/salt/minion.d/grains.conf
## Trigger a full Salt run
sudo salt-call state.apply
