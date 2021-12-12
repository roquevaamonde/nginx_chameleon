#!/usr/bin/env bash

# VARIABLES


#NGINX LOG [HOST MACHINE]

# nginx_log_path="/var/log/nginx_access.log" # Uncoment this line if you have running your nginx in your host machine and write the correct path to the log

#DOCKER CONTAINER LOGS

nginx_container="478249807b86913e678715627e0a3f28ec6eb70975c1995e47121e4e8b5da761" 
nginx_log_path="/var/lib/docker/containers/$nginx_container/$nginx_container-json.log" # comment this line if you have runnnig your nginx on host machine

# DEFAULT LOGS PATH VARIABLES

export workdire="/var/log/nginx_chameleon"
export word_dir="words_ban_log"
export nginx_log=$workdire/nginx.log
export int_log=$workdire/cham_ban_att.log
rules_path=/etc/nginx_chameleon
tmp_line="ftmp.linea"
hist_line="flinea"



# Functions

comprobar_dir_logs() {
  ls $workdire > /dev/null 2> /dev/null
  if [[ $? != 0  ]]
    then
     mkdir $workdire
     mkdir $workdire/$word_dir
  fi
}

scan_log() {

    nginx_container=$1
    tmp_line=$2
    hist_line=$3
    nginx_log_path=$4
    tail -n 1 $nginx_log_path > $tmp_line
    diff $tmp_line $hist_line > /dev/null 2> /dev/null
    if [[ $? != 0 ]]
      then
        cat $tmp_line > $hist_line
        cat $tmp_line >> $nginx_log
        res=1
    else
        res=0
    fi
    echo $res

}

extraer_datos() {
    linea=$1
    cat $linea | grep "\[error\]" > /dev/null 2> /dev/null
    if [[ $? == 0 ]]
      then
       is_error=1
    else
       is_error=0
    fi
    if [[ $is_error == 1 ]]
      then
        ip=$(cat $linea | awk -F':' '{ print $6 }' | awk '{ print $1 }' | awk -F',' '{ print $1 }')
        requested=$(cat $linea | awk -F':' '{ print $8 }' | awk -F',' '{ print $1 }')
        headers="[error]"
        error="[error]"
    else
        ip=$(cat $linea | awk -F'\"' '{ print $4 }' | awk '{ print $1 }')
        requested=$(cat $linea | awk -F'\"' '{ print $5 }')
        headers=$(cat $linea | awk -F'\"' '{ print $9 }')
        error=$(cat $linea | awk -F'\"' '{ print $6 }' | awk '{ print $1 }')
    fi
    respuesta="$ip+$requested+$error+$headers"
    echo $respuesta
}

banear_ip() {

 IP=$1
 iptables -I INPUT 1 -s $IP -j DROP
 iptables -I DOCKER-USER 1 -s $IP -j DROP

}

analizar_elemento() {
  lista_el_analizar=$1
  elemento=$2
  IP=$3
  REQUEST=$4
  HEADERS=$5
  tipo=$6
  for word in $(echo $lista_el_analizar | tr '_' ' ')
     do
      iptables -L -n | grep $IP > /dev/null 2> /dev/null
      if [[ $? == 0 ]]
        then
          break
      else
        time=$(echo $word | awk -F';' '{ print $3 }')
        wordd=$(echo $word | awk -F';' '{ print $2 }')
        word_ban_file=$workdire/$word_dir/$wordd.ban.log
        echo $elemento | grep $wordd > /dev/null 2> /dev/null
        if [[ $? == 0 ]]
          then
          veces=$(grep $IP $word_ban_file 2> /dev/null | wc -l)
          if [[ $veces -gt $(($time - 2)) ]]
            then
              if [[ $time == 0 ]]
                then
                  time=1
              fi
              echo "Se banea $IP por introducir $time veces la palabra $wordd en su peticion" >> $int_log
              banear_ip $IP
              echo "[$(date '+%d-%m-%Y %H:%M:%S')] MESSAGE: BANNED [IP: $IP, MATCH_TYPE: $tipo, MATCH: $wordd, TIMES: $time, LAST_REQUEST: ${REQUEST[@]}, LAST_HEADER: ${HEADERS[@]}]" >> $workdire/cham_ban.log
          else
              echo "Se resta una oportunidad a $IP por utilizar la palabra $wordd. Le quedan $(($(($time - 1)) - $veces)) intentos"   >> $int_log
              echo $IP >> $word_ban_file
          fi
        else
          continue
        fi
     fi
   done

}


comprobar_dir_logs

# CSV VARIABLES

rfl=$(cat $rules_path/rules.csv | grep request)
hfl=$(cat $rules_path/rules.csv | grep header)
efl=$(cat $rules_path/rules.csv | grep error)
ip_whitelist=$(cat $rules_path/rules.csv | grep "whitelist" | awk -F';' '{ print $2 }')

while true
  do
    tin=$(date +%s)
    hist=$workdire/$hist_line
    tmp=$workdire/$tmp_line
    if [[ $(scan_log $nginx_container $tmp $hist $nginx_log_path) == 1 ]]
      then
        data=$(extraer_datos $tmp)
        IP=$(echo $data | awk -F'+' '{ print $1 }')
        REQUEST=$(echo $data | awk -F'+' '{ print $2 }' | tr ' ' '_')
        ERROR=$(echo $data | awk -F'+' '{ print $3 }')
        HEADERS=$(echo $data | awk -F'+' '{ print $4 }' | tr ' ' '_')
        echo ${ip_whitelist[@]} | grep $IP > /dev/null 2> /dev/null
        if [[ $? == 0 ]]
          then
            continue
        fi
        echo "Analizando $IP"  
        analizar_elemento $(echo $rfl | tr ' ' '_') $REQUEST $IP $REQUEST $HEADERS "request"
        analizar_elemento $(echo $efl | tr ' ' '_') $ERROR $IP $REQUEST $HEADERS "error"
        analizar_elemento $(echo $hfl | tr ' ' '_') $HEADERS $IP $REQUEST $HEADERS "header"
    else
      continue
    fi
    ten=$(date +%s)
    echo "Tiempo de escaneado: $(($tin - $ten)) ms"
done
