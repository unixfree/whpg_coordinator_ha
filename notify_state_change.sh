#!/bin/bash
# /etc/keepalived/notify_state_change.sh

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
CURRENT_STATE="$1" # MASTER, BACKUP, FAULT, STOP
COORDINATOR_DATA_DIRECTORY=/data/coordinator/gpseg-1
VIP="192.168.1.100"
IFACE="eth1"

# (Optional) Add notification
case "$CURRENT_STATE" in
    "MASTER")
        logger "$TIMESTAMP INFO: Keepalived [$HOSTNAME] MASTER state. Starting WarehousePG..."
        # Add MASTER specific actions here
        sudo -u gpadmin -i gpactivatestandby -f -d $COORDINATOR_DATA_DIRECTORY -q -a
        SERVICE_START_STATUS=$?

        if [ $SERVICE_START_STATUS -eq 0 ]; then
            logger "$TIMESTAMP INFO: Keepalived [$HOSTNAME] WarehousePG started successfully."
        else
            logger "$TIMESTAMP ERROR: Keepalived [$HOSTNAME] Failed to start WarehousePG (Exit Code: $SERVICE_START_STATUS)."
        fi

        # Example: Verifying connection to a virtual IP
        ping -c 1 $VIP > /dev/null
        if [ $? -eq 0 ]; then
            logger "$TIMESTAMP INFO: Keepalived [$HOSTNAME] VIP $VIP is reachable."
        else
            echo "$TIMESTAMP ERROR: Keepalived [$HOSTNAME] VIP $VIP is NOT reachable."
        fi
        ;;
    "BACKUP")
        logger "$TIMESTAMP INFO: Keepalived [$HOSTNAME] BACKUP state"
        # Add BACKUP specific actions here, when stop by kill -9 Postmaster 
        # rm /tmp/.s.PGSQL.5432
	    # rm /tmp/.s.PGSQL.5432.lock
        ;;
    "FAULT")
        logger "$TIMESTAMP ERROR: Keepalived [$HOSTNAME] FAULT state"
        # when state is FAULT,shutdown WarehousePG when down interface or unplug network cable
		# for prevent brain split.
        sudo -u gpadmin -i /usr/local/greenplum-db/bin/pg_ctl stop -D $COORDINATOR_DATA_DIRECTORY
		if [ $? -eq 0 ]; then
		    logger "$TIMESTAMP INFO: Keepalived [$HOSTNAME] WHPG stopped"
        else
			rm /tmp/.s.PGSQL.5432
	        rm /tmp/.s.PGSQL.5432.lock
			logger "$TIMESTAMP INFO: Keepalived [$HOSTNAME] deleted /tmp/.s.PGSQL.532"
        fi
        ;;
    "STOP")
        logger "$TIMESTAMP INFO: Keepalived [$HOSTNAME] STOP state"
        # Add STOP specific actions here
        # Remove VIP
        sudo ip addr del ${VIP}/24 dev ${IFACE}
        # clear ARP Cache (notify new VIP)
        arping -c 3 -I ${IFACE} ${VIP}
        ;;
    *)
        # MASTER, BACKUP, FAULT, STOP 외의 알 수 없는 상태
        logger "$TIMESTAMP ERROR: Keepalived [$HOSTNAME] Unknown state $CURRENT_STATE"
        ;;
esac

exit 0
