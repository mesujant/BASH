# find all missing log rotation logs
for folder in $(find ./ -type d /var/log/syslogng); 
do  
	syslogs=$(ls /var/log/syslogng/$folder); 
	if ! echo $syslogs |  grep -q ".gz" ;
	then 
		echo /var/log/syslogng/$folder; 
	fi; 
done;

