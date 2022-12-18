# find all missing log rotation logs
for folder in $(find /var/log/syslogng/ -type d); 
do  
	syslogs=$(ls $folder); 
	if ! echo $syslogs |  grep -q ".gz" ;
	then 
		echo $folder; 
	fi; 
done;

