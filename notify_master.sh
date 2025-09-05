#!/bin/bash
# /etc/keepalived/notify_master.sh

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
CURRENT_STATE="$1"    # Third argument passed to notify script (MASTER, BACKUP, FAULT)

logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived State changed to $CURRENT_STATE by notify_master.sh"

if [ "$CURRENT_STATE" == "MASTER" ]; then
    logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived This node is now MASTER. Starting WHPG..."
    # Example: Web service start command
    # sudo /usr/bin/systemctl start my_service.service
    export COORDINATOR_DATA_DIRECTORY=/data/master/gpseg-1
    sudo -u gpadmin -i gpactivatestandby -f -d $COORDINATOR_DATA_DIRECTORY -q -a

    SERVICE_START_STATUS=$?

    if [ $SERVICE_START_STATUS -eq 0 ]; then
        logger "$TIMESTAMP SUCCESS: [$HOSTNAME] Keepalived WHPG started successfully."
    else
        logger "$TIMESTAMP ERROR: [$HOSTNAME] Keepalived Failed to start WHPG (Exit Code: $SERVICE_START_STATUS)."
        # Additional actions to take if service start fails (e.g. emergency notification)
        # logger "ERROR: Service start failed on $HOSTNAME during failover!" | mail -s "Keepalived Critical Alert" admin@example.com
    fi

    # Example: Verifying connection to a virtual IP
    # ping -c 1 192.168.1.100 > /dev/null
    # if [ $? -eq 0 ]; then
    #     echo "$TIMESTAMP INFO: [$HOSTNAME - $VRRP_INSTANCE_NAME] VIP 192.168.1.100 is reachable." >> "$LOG_FILE"
    # else
    #     echo "$TIMESTAMP ERROR: [$HOSTNAME - $VRRP_INSTANCE_NAME] VIP 192.168.1.100 is NOT reachable." >> "$LOG_FILE"
    # fi

else    # Execute notify_master script when in BACKUP or FAULT state (when using notify script)
    logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived Executing notify_master.sh in $CURRENT_STATE state, no action taken."
fi

exit 0
