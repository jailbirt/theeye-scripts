#!/bin/bash
#Chequea web, permite diferencial días hábiles de fines de semana y feriados (solo argentina)
url=$1
regex=$2
## Optional ##
onlyWorkable="${3:-no}" #En yes, solo alerta los días hábiles.
proxy="${4:-}"
##
alert="yes"

#Return if today is a workable day.
function isWorkable () 
{
 timeZone="America/Buenos_Aires "
 day=$(env TZ="$timeZone" date '+%d')
 month=$(env TZ="$timeZone" date '+%m')
 year=$(env TZ="$timeZone" date '+%Y')
 dayOfWeek=$(env TZ="$timeZone" date '+%u')
 
 if [ ! -f /tmp/feriados$year ];then
  curl --silent --max-time 5 -X GET http://nolaborables.com.ar/api/v2/feriados/2019 |jq ".[] | select((.dia==$day) and .mes==$month)" > /tmp/feriados$year
 fi
 if $proxy cat /tmp/feriados$year |grep motivo > /dev/null ;then
    echo "feriado"
    alert="no"
 elif ((dayOfWeek > 5));then
    echo "finde"
    alert="no"
 else 
    echo "workable"
    alert="yes"
 fi
}

if [ "$onlyWorkable" == "yes" ]; then
 #isWorkable $day $month $dayOfWeek 
 echo "solo habiles"
 isWorkable
fi

if [ -z "$url" ] || [ -z "$regex" ];then
 echo please run "$0" url regex
 exit
fi


result=$(https_proxy=$proxy curl -L --silent --max-time 5 --insecure "$url" | grep "$regex") 
#echo "https_proxy=$proxy curl --silent --max-time 5 --insecure \"$url\" | grep \"$regex\" "
status="SUCCESS"
if [ "$result" == "" ] && [ "$alert" == "yes" ];then
 status="FAILURE"
fi
echo $status
