#!/usr/bin/env bash

bin_dir=/usr/local/bin
config_dir=/etc/nginx_chameleon
serv_dir=/lib/systemd/system

comprobar_directorios() {
   ls $config_dir > /dev/null 2>&1
   if [[ $? != 0]]
      mkdir $config_dir
}

cp ./rules.csv $config_dir
cp ./fcham.sh $bin_dir/fcham.sh
cp ./nx_chameleon.service $serv_dir/nx_chameleon.service

chmod u+x $bin_dir/fcham.sh
systemctl enable nginx_chameleon
systemctl start nginx_chameleon