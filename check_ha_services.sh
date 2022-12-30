#!/bin/bash
#26th Dec 2022
#Sujan Tamang
#To monitor service as a service basis
#set -x

GOOD=0
WARNING=1
CRITICAL=2
UNKNOWN=3

function check_individual_service {
	usage() {
		echo "$(pwd)/check_services.sh -H <Host Address> -S <Program name>";
		exit 1;
	}

	while getopts ":H:S:" opts
	do
		case "$opts" in
		H) hostname=${OPTARG};;
		S) service=${OPTARG};;
		?) usage;;
		esac
	done


	case "$service" in
	nginx) process="nginx: master process /usr/sbin/nginx";;
	#haproxy) process="haproxy-systemd";;
	php-fpm) process="php-fpm: master";;
	php7-fpm) process="php7-fpm: master";;
	docker) process="dockerd";;
	*) process=$service;;
	esac  

	if [ -z $hostname ] || [ -z $service ];
	then
		usage
	fi

	get_output=$(snmpget -v 2c -c snmpAgent $hostname SNMPv2-MIB::sysDescr.0)

	if [ -z "$get_output" ]
	then
		echo $UNKNOWN
	fi

	pid=`snmpwalk -v 2c -c snmpAgent $hostname HOST-RESOURCES-MIB::hrSWRunPath | grep -w "$process" | awk -F'=' '{print $1}' | awk -F'.' '{print $NF}' | head -1`

	if [ -z "$pid" ]
	then
		echo $CRITICAL
	else
		service_status=`snmpwalk -v 2c -c  snmpAgent $hostname HOST-RESOURCES-MIB::hrSWRunStatus.${pid} | awk -F'=' '{print $2}'`
		if echo "$service_status" | grep -q runnable || echo "$service_status" | grep -q running;
		then
			echo $GOOD
		fi
	fi
}


function get_responses {
        i=0;
        response=()
        while [ $i -le "$#" ];do
                if [ $i -gt 1 ];then
                        response[$i]=$(check_individual_service -S $1 -H ${!i})
                fi; 
                i=$(( $i + 1 ))
        done
        echo ${response[@]}
}


function main {
	no_of_hosts=$(echo "$# - 1" | bc)
	responses=$(get_responses $@)
	if [ $(echo ${responses} | grep -o $CRITICAL | wc -w) -eq $no_of_hosts ]; then
		echo "$@  down.."
		exit $CRITICAL
	elif [ $(echo ${responses} | grep -o $GOOD | wc -w) -eq $no_of_hosts ]; then
		echo "$@  running.."
		exit $GOOD
	elif [ $(echo ${responses} | grep -o $UNKNOWN | wc -w) -eq $no_of_hosts ]; then
		echo "$@  UNKNOWN.."
		exit $UNKNOWN
	else
		j=2
		host_with_service_down=""
		host_with_service_up=""
		host_with_service_unknown=""
		for response in ${responses};do
			if [ $response -eq $CRITICAL ];then
				host_with_service_down=$host_with_service_down" ${!j}"
			elif [ $response -eq $GOOD ];then
				host_with_service_up=$host_with_service_up" ${!j}"
			else
				host_with_service_unknown=$host_with_service_unknown" ${!j}"
			fi
			j=$(( j + 1 ))
		done;
		echo "${!1} down: ${host_with_service_down} up:${host_with_service_up} unknown: ${host_with_service_unknown}"
		exit $WARNING
	fi;
}
main $@

