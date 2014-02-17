#!/bin/bash
. /opt/asha/asha.conf

[ -e /opt/asha/.configured_drbd ] && echo "DRBD is already configured - ending" && exit 4

# set-up drbd for the first time
[ ! -e /drbd ] && mkdir /drbd
 
if [ "$PRIMARY" = "true" ]; then
   echo "Running for a new cluster"
else
   echo "Running for an existing cluster"
fi 
 
# do some checks
echo "Looking for DRBD at $DRBDDEV..."
[ -e /proc/drbd  ] && echo "drbd is already active - nothing to do" && exit 4

fdisk -l | grep "$DRBDDEV"
[  "$?" -ne "0" ] && echo "The drbd partition $DRBDDEV does not exist on this server!!" && exit 8
echo "Found $DRBDDEV..."

# get the config
echo "copying drbd.d/r0.res from cache"
cp /opt/asha/cache/drbd.d/r0.res /etc/drbd.d/
chmod 744 /etc/drbd.d/r0.res

# create the drbd 
echo "creating DRBD"
drbdadm create-md r0
echo "Done" 

if [ "$PRIMARY" = "true" ]; then
#start the drbd
	echo "starting DRBD" 
	/etc/init.d/drbd start
	echo "Done"
#make me the primary
   echo "declaring primary to DRBD"
   drbdadm -- --overwrite-data-of-peer primary r0 

#Create a filesystem on the primary 
   echo "creating an ext3 filesystem on $DRBDDEV"
   mke2fs -j /dev/drbd0
 
# Now we can mount it
   echo "Mounting $DRBDDEV on /drbd"
   mount /dev/drbd0 /drbd
#show the mount
   mount
fi
touch /opt/asha/.configured_drbd

echo "drbd done"
#
#done
