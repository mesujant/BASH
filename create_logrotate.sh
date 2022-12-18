# find all missing log rotation logs
# create individual logs folder file in logrotate
folders="/var/log/syslogng/wifinepal"
for folder in $folders; do 
	target_filename=$(basename $folder)
	cat << EOF > $targ$target_filename
$folder/*.log {
	daily
	rotate 90
	copytruncate
	missingok
	compress
	notifempty
	dateext
	dateformat -%Y-%m-%d
}
EOF
done;

