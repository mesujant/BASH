#!/bin/bash
set x
preprocess () {
	IPTABLES=$(which iptables)
	if [ ! -z $IPTABLES ]; then
		IPTABLES_SAVE=$(which iptables-save)
		$IPTABLES_SAVE > /tmp/iptables_$(date +%F)
	else
		echo "iptables not found"
	fi

}
remove_inactive_rules () {
	IPTABLES_CHAINS="INPUT"
	for chain in $IPTABLES_CHAINS; do
		while (iptables -nvL $chain | grep -m 1 "0 ACCEPT"); do
			echo " $chain $rules_no";
			rules_no=$(iptables -nvL $chain --line | grep -m 1 "0 ACCEPT" | cut -d" " -f1)
			iptables -D $chain $rules_no;
			
			
		done;
	done;
	# for output chain remove all rules with state traacking and default drop
	iptables -I OUTPUT 1 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
	while [ ! -z "$(iptables -nvL OUTPUT 2)" ]; do
		iptables -D OUTPUT 2
	done;
}

post_process() {
	iptables -N LOGGING
#	iptables -A INPUT -j LOGGING
#	iptables -A OUTPUT -j LOGGING
#	iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPtables-Dropped: " --log-level 4
#	iptables -A LOGGING -j DROP
}

reload_iptables () {
	# check os vesrion and proceed accordingly
	release=$(cat /etc/*release)
	if echo $release | grep -iq ubuntu; then
		netfilter-persistent reload
		netfilter-persistent reload
	elif echo $release | grep -iq centos; then
		service iptables save
		service iptables reload

	else
		echo "machnine os type couldnot be determined"
	fi;
}

check_base_rules () {
	ansible-playbook -i hosts iptables.yml
}

preprocess
post_process
check_base_rules
remove_inactive_rules
reload_iptables
