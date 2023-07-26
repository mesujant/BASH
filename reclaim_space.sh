#!/bin/bash
#Author:        Sujan Tamang
#Date:          26th Jul, 2023
#Purpose:       relaim space from already deleted files of syslog-ng

truncate_deleted() {
        pid=$(/sbin/pidof $1)
        deleted_fds=$(ls -l /proc/$pid/fd | grep deleted | awk -F" " '{print $9}')
        for fd in $deleted_fds;
        do
                ls -l /proc/$pid/fd/$fd >> ./reclaim_logs/reclaim-$(date +%F-%H-%M-%S).log
                echo > /proc/$pid/fd/$fd
        done;

}

reclaim_deleted_space() {
        truncate_deleted $1
}

reclaim_deleted_space syslog-ng

