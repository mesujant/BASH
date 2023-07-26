#!/bin/bash
#Nov 12 2021
#Sujan Tamang
#To monitor containers

GOOD=0
WARNING=1
CRITICAL=2
UNKNOWN=3

usage() {
        echo "$(pwd)/check_services.sh -H <Host Address>";
        exit 1;
}

while getopts ":H:" opts
do
        case "$opts" in
        H) hostname=${OPTARG};;
        ?) usage;;
        esac
done


if [ -z $hostname ];
then
        usage
fi

get_output=$(curl -s --connect-timeout 5 $hostname:2376/containers/json?all=true)
if [ -z "$get_output" ]
then
        echo "No response from remote server $hostname"
        exit $UNKNOWN
fi
cont_count=$(( $(echo $get_output | /bin/jq '.[].Id' | wc -l) - 1 ))
EXIT_STATUS=$GOOD
STATUS_MESSAGE="CRITICAL: "

for i in $(seq 0 $cont_count);do
        state=$(echo $get_output | jq ".[$i].State");
        if ! [ $state = '"running"' ]; then 
                STATUS_MESSAGE+=$(echo $get_output | jq ".[$i].Names[0]")
                EXIT_STATUS=$CRITICAL
        fi;
done;

if [ $EXIT_STATUS -eq $GOOD ]; then
        echo "all containers are running.."
else
        echo "$STATUS_MESSAGE is not running"
fi;

exit $EXIT_STATUS

