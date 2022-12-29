#!/bin/bash
#26th Dec 2022
#Sujan Tamang
#To monitor service as a service basis


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

	pid=`snmpwalk -v 2c -c snmpAgent $hostname HOST-RESOURCES-MIB::hrSWRunPath | grep -w "$process" | awk -F'=' '{print $1}' | awk -F'.' '{print $NF}' | head -1`

	if [ -z "$pid" ]
	then
		echo 0
	else
		service_status=`snmpwalk -v 2c -c  snmpAgent $hostname HOST-RESOURCES-MIB::hrSWRunStatus.${pid} | awk -F'=' '{print $2}'`
		if echo "$service_status" | grep -q runnable || echo "$service_status" | grep -q running;
		then
			echo 1
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
	responses=$(get_responses $@)
	if ! echo ${responses} | grep -q 1;then
		echo "$@ services down.."
		exit $CRITICAL
	elif ! echo ${responses} | grep -q 0;then
		echo "$@ services running.."
		exit $GOOD
	else
		j=2
		host_with_service_down=""
		host_with_service_up=""
		for response in ${responses};do
			if [ $response -eq 0 ];then
				host_with_service_down=$host_with_service_down" ${!j}"
			else
				host_with_service_up=$host_with_service_up" ${!j}"
			fi
			j=$(( j + 1 ))
		done;
		echo "$1 down: ${host_with_service_down} up:${host_with_service_up}"
		exit $WARNING
	fi;
}
main $@

