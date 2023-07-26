# separate partition for docker ??
if ! systemctl status docker  | grep -q "Loaded: loaded"; then
	export https_proxy=http://http-proxy.wlink.com.np:5178 
	export http_proxy=http://http-proxy.wlink.com.np:5178 
	apt-get remove docker docker-engine docker.io containerd runc
	 apt-get update -y

	 apt-get install  -y \
		    ca-certificates \
			curl \
			    gnupg \
				lsb-release
	 mkdir -p /etc/apt/keyrings
	 curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	 echo \
		   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
		     $(lsb_release -cs) stable" |  tee /etc/apt/sources.list.d/docker.list > /dev/null

	  apt-get update -y
	  apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
	  systemctl enable docker
	  systemctl start docker
else
	echo "docker already Loaded"
fi


# docker proxy
if [ ! -d /etc/systemd/system/docker.service.d ]; then
	mkdir -p  /etc/systemd/system/docker.service.d
	cat << EOF > /etc/systemd/system/docker.service.d/http-proxy.conf 
[Service]
Environment="HTTP_PROXY=http://http-proxy.wlink.com.np:5178"
Environment="HTTPS_PROXY=http://http-proxy.wlink.com.np:5178"
Environment="NO_PROXY=.wlink.com.np,10.0.0.0/8,.worldlink.com.np"
EOF
	systemctl daemon-reload
	systemctl restart docker
else
	echo "proxy already added"
fi

#install docker-compose
apt install docker-compose -y

 # cadvisor
sudo docker run   --volume=/:/rootfs:ro   --volume=/var/run:/var/run:ro   --volume=/sys:/sys:ro   --volume=/var/lib/docker/:/var/lib/docker:ro   --volume=/dev/disk/:/dev/disk:ro   --publish=8080:8080   --detach=true   --name=cadvisor  --restart=always gcr.io/cadvisor/cadvisor

# install portainer agent
docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest

# install snmp
apt-get install snmpd -y
#change rocommunity
cp -p /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bck
echo 'rocommunity snmpAgent' > /etc/snmp/snmpd.conf

# install node_exporter
docker run -d -p 9100:9100 --name node-exporter --restart=always bitnami/node-exporter:latest

# add user ci-executor
useradd -G sudo ci-executor
# add user wlansible
useradd -G wlansible wlansible

# start and enable services.
systemctl start docker
systemctl enable docker

# enable memory swappiness in host



# iptables
apt-get install iptables-persistent -y

#:INPUT DROP [4:483]
#:FORWARD DROP [0:0]
#:OUTPUT ACCEPT [1395:341715]
#:DOCKER - [0:0]
#:DOCKER-ISOLATION-STAGE-1 - [0:0]
#:DOCKER-ISOLATION-STAGE-2 - [0:0]
#:DOCKER-USER - [0:0]
#-A INPUT -i lo -j ACCEPT
#-A INPUT -p icmp -j ACCEPT
#-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
#-A INPUT -s 202.79.32.85/32 -p tcp -m tcp --dport 22 -m comment --comment "log -> ssh" -j ACCEPT
#-A INPUT -s 202.79.36.170/32 -p tcp -m tcp --dport 22 -m comment --comment "ci[ANSIBLE] -> ssh" -j ACCEPT
#-A INPUT -s 10.12.9.12/32 -p tcp -m tcp --dport 9100 -m comment --comment "server-mon->node_exporter" -j ACCEPT
#-A INPUT -s 202.79.32.94/32 -p udp -m udp --dport 161 -m comment --comment "nagios-srv-01 -> snmpd" -j ACCEPT

# install docker SDK,
apt-get install python3-pip -y
pip3 install docker 

# enable file log for docker service
mkdir -p /var/log/docker
sed -i 's@\[Service\]@\[Service\]\nStandardOutput=append:/var/log/docker/docker.log\nStandardError=append:/var/log/docker/docker.log@g' /lib/systemd/system/docker.service

#sed 's@\[Service\]@\[Service\]\nStandardOutput=append:/var/log/docker/docker.log@g' 
#sed 's@\[Service\]@\[Service\]\nStandardError=append:/var/log/docker/docker.log@g'
systemctl daemon-reload
systemctl restart docker

# add daemon.json for docker service
cat << EOF > /etc/docker/daemon.json
{

        "tls": false,
        "hosts": ["tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"],
	"debug": true
}

EOF
sed -i "s@^ExecStart=.*@ExecStart=/usr/bin/dockerd@g" /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker

