#!/bin/bash
# /etc/keepalived/notify_state_change.sh
# General script to log all VRRP state changes

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
CURRENT_STATE="$1" # MASTER, BACKUP, FAULT, STOP
COORDINATOR_DATA_DIRECTORY=/data/coordinator/gpseg-1
VIP="192.168.1.100"

logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived state changed to $CURRENT_STATE by notify_state_change.sh"

# (Optional) Add notification
# if [ "$CURRENT_STATE" == "MASTER" ]; then
#   echo "$TIMESTAMP INFO: [$HOSTNAME] Keepalived MASTER on $HOSTNAME" | mail -s "HA Event" admin@example.com
# elif [ "$CURRENT_STATE" == "BACKUP" ]; then
#   echo "$TIMESTAMP INFO: [$HOSTNAME] Keepalived BACKUP on $HOSTNAME" | mail -s "HA Event" admin@example.com
# fi

# (Optional) Add notification
case "$CURRENT_STATE" in
    "MASTER")
        logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived This node is now MASTER. Starting WHPG..."
        # Add MASTER specific actions here
        sudo -u gpadmin -i gpactivatestandby -f -d $COORDINATOR_DATA_DIRECTORY -q -a
        SERVICE_START_STATUS=$?

        if [ $SERVICE_START_STATUS -eq 0 ]; then
            logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived WHPG started successfully."
        else
            logger "$TIMESTAMP ERROR: [$HOSTNAME] Keepalived Failed to start WHPG (Exit Code: $SERVICE_START_STATUS)."
        fi

        # Example: Verifying connection to a virtual IP
        ping -c 1 $VIP > /dev/null
        if [ $? -eq 0 ]; then
            logger "$TIMESTAMP INFO: [$HOSTNAME] VIP $VIP is reachable."
        else
            echo "$TIMESTAMP ERROR: [$HOSTNAME] VIP $VIP is NOT reachable."
        fi
        ;;
    "BACKUP")
        logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived BACKUP on $HOSTNAME"
        # Add BACKUP specific actions here, when stop by kill -9 Postmaster 
        rm /tmp/.s.PGSQL.5432
	    rm /tmp/.s.PGSQL.5432.lock
        ;;
    "FAULT")
        logger "$TIMESTAMP ERROR: [$HOSTNAME] Keepalived FAULT on $HOSTNAME DEBUG EDB"
        # when state is FAULT,shutdown WarehousePG DB when down interface or unplug network cable
		# for prevent brain split.
        sudo -u gpadmin -i /usr/local/greenplum-db/bin/pg_ctl stop -D /data/coordinator/gpseg-1
        ;;
    "STOP")
        logger "$TIMESTAMP INFO: Keepalived STOPPED on $HOSTNAME DEBUG EDB"
        # (Optional) Add STOP specific actions here
        ;;
    *)
        # MASTER, BACKUP, FAULT, STOP 외의 알 수 없는 상태
        logger "$TIMESTAMP ERROR: Keepalived Unknown state $CURRENT_STATE on $HOSTNAME"
        ;;
esac

exit 0
