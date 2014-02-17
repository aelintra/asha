#!/bin/bash
#
# give control to corosync and pacemaker
#
. /opt/asha/asha.conf
. /etc/default/corosync

[ "$START" = "yes" ] && echo "corosync already configured" && exit 4

echo "START=yes" > /etc/default/corosync
cp /opt/asha/cache/corosync/corosync.conf /etc/corosync

update-rc.d -f mysql remove 
update-rc.d -f apache2 remove 
/etc/init.d/mysql stop
/etc/init.d/apache2 stop

corosync

if [ -e /opt/sark/db/sark.db ]; then
	if [ -e /usr/sbin/crm_mon ]; then
		grep -q 'crm_mon' /etc/rc.local
		if [ $? != 0 ]; then
			sed -i '${/^exit 0$/d}' /etc/rc.local
			echo "[ -e /usr/sbin/crm_mon ] && crm_mon --daemonize --as-html /opt/sark/www/crm_mon.htm" >> /etc/rc.local
			echo "exit 0" >> /etc/rc.local
		fi
		crm_mon --daemonize --as-html /opt/sark/www/crm_mon.htm
	fi
fi	
