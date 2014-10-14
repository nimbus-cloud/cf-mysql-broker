#!/bin/bash
sudo /etc/init.d/mysql stop
sudo /bin/bash -c "rm -rfv /var/lib/mysql/*"
sudo mysql_install_db
sudo /etc/init.d/mysql start
echo "CREATE DATABASE test" | mysql -uroot
rake db:migrate RAILS_ENV=test

