#!/usr/bin/env bash

set -x -e

sudo apt-get update 2> /dev/null

sudo apt-get install -y make 2> /dev/null

sudo apt-get install -y vim 2> /dev/null

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password ROOTPASSWORD'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password ROOTPASSWORD'
sudo apt-get install -y mysql-server 2> /dev/null
sudo apt-get install -y mysql-client 2> /dev/null

mysqladmin -u root -pROOTPASSWORD password ''

cat <<EOT > /etc/mysql/conf.d/utf8.cnf
[mysqld]
character-set-server=utf8
collation-server = utf8_unicode_ci
init-connect='SET NAMES utf8'
init_connect='SET collation_connection = utf8_unicode_ci'
skip-character-set-client-handshake
EOT

/etc/init.d/mysql restart

echo "CREATE DATABASE test" | mysql -uroot
#echo "ALTER DATABASE test CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -uroot 
#echo "SET collation_connection = 'utf8_general_ci'" mysql -uroot 

sudo apt-get install -y git curl libmysqlclient-dev 2> /dev/null


su - vagrant <<'EOF'
curl -sSL https://get.rvm.io | bash -s stable
source /home/vagrant/.rvm/scripts/rvm
rvm install ruby-2.0.0-p353

cd /vagrant
bundle install
rake db:migrate RAILS_ENV=test
EOF

