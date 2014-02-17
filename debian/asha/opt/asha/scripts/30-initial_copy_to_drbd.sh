#!/bin/bash
# copy source files into drbd. - ONLY run this ONCE on the primary and NEVER on the secondary
# 
#
. /opt/asha/asha.conf

[ ! "$PRIMARY" = "true" ] && echo "This is not the first node defined - will not copy anything!" && exit 4

mount | grep -q '/dev/drbd0 on /drbd'
[  "$?" -ne "0" ] && echo "/dev/drbd0 is not mounted on /drbd - cannot copy anything!" && exit 4

if [ -e /usr/sbin/asterisk ]; then
	[ ! -e /drbd/var/lib/asterisk ] && mkdir -p /drbd/var/lib/asterisk && cp -a /var/lib/asterisk /drbd/var/lib && echo "copied /var/lib/asterisk"
	[ ! -e /drbd/etc/asterisk ] && mkdir -p /drbd/etc/asterisk && cp -a /etc/asterisk /drbd/etc && echo "copied /etc/asterisk"
	[ ! -e /drbd/var/log/asterisk ] && mkdir -p /drbd/var/log/asterisk && cp -a /var/log/asterisk /drbd/var/log && echo "copied /var/log/asterisk"
	[ ! -e /drbd/var/spool/asterisk ] && mkdir -p /drbd/var/spool/asterisk && cp -a /var/spool/asterisk /drbd/var/spool && echo "copied /var/spool/asterisk"
else
	echo "Asterisk not installed; not copying Asterisk files"
fi

if [ -e /usr/bin/mysql ]; then
	[ ! -e /drbd/var/lib/mysql ] && mkdir -p /drbd/var/lib/mysql && cp -a /var/lib/mysql /drbd/var/lib && echo "copied /var/lib/mysql"
else
	echo "MySQL not installed; not copying MySQL files"
fi

if [ -e /opt/sark ]; then 
	[ ! -e /drbd/opt/sark/db ] && mkdir -p /drbd/opt/sark/db && cp -a /opt/sark/db /drbd/opt/sark && echo "copied /opt/sark/db"
else 
	echo "SARK not installed; not copying SARK database"
fi


