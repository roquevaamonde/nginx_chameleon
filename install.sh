#!/usr/bin/env bash

bin_dir=/usr/local/bin
config_dir=/etc/nginx_chameleon
serv_dir=/lib/systemd/system
workdire="/var/log/nginx_chameleon"
word_dir="words_ban_log"


comprobar_directorios() {
   config_dir=$1	
   ls $config_dir > /dev/null 2>&1
   if [[ $? != 0 ]]
     then	   
      mkdir $config_dir
   fi
}
comprobar_dir_logs() {
  workdire=$1
  word_dir=$2


  ls $workdire > /dev/null 2> /dev/null
  if [[ $? != 0  ]]
    then
     mkdir $workdire
     mkdir $workdire/$word_dir
  fi
}

comprobar_directorios $config_dir
comprobar_dir_logs $workdire $word_dir

cp ./rules.csv $config_dir/rules.csv
cp ./fcham.sh $bin_dir/fcham.sh
cp ./nx_chameleon.service $serv_dir/nx_chameleon.service

chmod u+x $bin_dir/fcham.sh
systemctl enable nx_chameleon
systemctl start nx_chameleon
