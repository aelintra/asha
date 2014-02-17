#!/bin/bash
. /opt/asha/asha.conf

[ ! -e /opt/sark ] && echo "SNO !! SARK not installed - exiting" && exit 4
[ ! -e /sbin/shorewall ] && echo "SNO!! Shorewall not installed - exiting" && exit 8
grep -q 'interfaces.d' /etc/network/interfaces
if [ "$?" -ne "0" ]; then
	echo "interfaces.d/* is not sourced in interfaces -"
	echo "you probably have the wrong release of sark installed!"
	exit 12
fi	

echo "updating sark database"
for file in `ls -d /opt/asha/amacs/*` ; do
echo "Applying amacs $file to the DB"
sqlite3 /opt/sark/db/sark.db < $file
done
#run the generator
echo "running the generator"
sh /opt/sark/scripts/srkgenAst

RESTART=0

if [ "$USENIC1" = "true" ]; then 
	if [ -e /etc/network/interfaces.d/eth1 ]; then
		echo "removing existing eth1 definition - eth1 will come down"
		ifdown eth1
		rm -f /etc/network/interfaces.d/eth1
	fi	
	if [ ! -e /etc/network/interfaces.d ]; then
		echo "creating non-existent /etc/network/interfaces.d"
		mkdir /etc/network/interfaces.d
	fi
	echo "copying new interface eth1 definition"
	cp /opt/asha/cache/interfaces.d/eth1 /etc/network/interfaces.d
	echo "bringing up eth1"
	ifup eth1

	if [ ! -e /opt/asha/.configured_shorewall ]; then
       		cp /opt/asha/cache/shorewall/interfaces /etc/shorewall/interfaces
       		cp /opt/asha/cache/shorewall/policy /etc/shorewall/policy
       		cp /opt/asha/cache/shorewall/zones /etc/shorewall/zones
       		echo "Shorewall rule files copied from cache"
       		touch /opt/asha/.configured_shorewall
		RESTART=1
	fi
fi	

grep -q 'ACCEPT net:$LAN $FW udp 5404' /etc/shorewall/sark_rules 
if [  "$?" -ne "0" ] ; then
	echo 'ACCEPT net:$LAN $FW udp 5404:5405' >> /etc/shorewall/sark_rules
	echo "Eth0 added rule UDP/5404"
	RESTART=1
else
	echo "Eth0 UDP/5404 rule exists - not added"   
fi
grep -q 'ACCEPT net:$LAN $FW tcp 7788' /etc/shorewall/sark_rules    
if [  "$?" -ne "0" ] ; then
	echo 'ACCEPT net:$LAN $FW tcp 7788:7789' >> /etc/shorewall/sark_rules
	echo "Eth0 added rule TCP/7788"
	RESTART=1
else
	echo "Eth0 TCP/7788 rule exists - not added"
fi

if [ "$USENIC1" = "true" ]; then
	grep -q 'ACCEPT clst $FW udp 5404' /etc/shorewall/sark_rules 
	if [  "$?" -ne "0" ] ; then
		echo 'ACCEPT clst $FW udp 5404:5405' >> /etc/shorewall/sark_rules
		echo "Eth1 added rule UDP/5404"
		RESTART=1
	else
		echo "Eth1 UDP/5404 rule exists - not added"   
	fi
	grep -q 'ACCEPT clst $FW tcp 7788' /etc/shorewall/sark_rules    
	if [  "$?" -ne "0" ] ; then
		echo 'ACCEPT clst $FW tcp 7788:7789' >> /etc/shorewall/sark_rules
		echo "Eth1 added rule TCP/7788"
		RESTART=1
	else
		echo "Eth1 TCP/7788 rule exists - not added"
	fi
fi

[ "$RESTART" -eq "1" ] && echo "restarting shorewall" && /sbin/shorewall restart


