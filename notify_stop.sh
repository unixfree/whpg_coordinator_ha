#!/bin/bash
# /etc/keepalived/notify_stop.sh

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
CURRENT_STATE="$1" # MASTER, BACKUP, FAULT

logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived delete VIP $CURRENT_STATE by notify_stop.sh"

VIP="192.168.56.100"
IFACE="eth1"
SERVICE_NAME="service"

# Remove VIP
sudo ip addr del ${VIP}/24 dev ${IFACE}
# Down 	Interbase
#sudo ip link set dev ${IFACE} down 

# clear ARP Cache (notify new VIP)
arping -c 3 -I ${IFACE} ${VIP}

exit 0

# (Options) add Alert
# if [ "$CURRENT_STATE" == "MASTER" ]; then
#   echo "Keepalived: MASTER on $HOSTNAME" | mail -s "HA Event" admin@example.com
# elif [ "$CURRENT_STATE" == "BACKUP" ]; then
#   echo "Keepalived: BACKUP on $HOSTNAME" | mail -s "HA Event" admin@example.com
# fi

exit 0
