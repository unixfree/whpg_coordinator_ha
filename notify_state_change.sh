#!/bin/bash
# /etc/keepalived/notify_state_change.sh
# General script to log all VRRP state changes

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)
CURRENT_STATE="$1" # MASTER, BACKUP, FAULT, STOP

logger "$TIMESTAMP INFO: [$HOSTNAME] Keepalived state changed to $CURRENT_STATE by notify_state_change.sh"

# (Optional) Add notification
# if [ "$CURRENT_STATE" == "MASTER" ]; then
#   echo "Keepalived: MASTER on $HOSTNAME" | mail -s "HA Event" admin@example.com
# elif [ "$CURRENT_STATE" == "BACKUP" ]; then
#   echo "Keepalived: BACKUP on $HOSTNAME" | mail -s "HA Event" admin@example.com
# fi

# (Optional) Add notification
case "$CURRENT_STATE" in
    "MASTER")
        logger "Keepalived: MASTER on $HOSTNAME DEBUG EDB"
        #echo "Keepalived: MASTER on $HOSTNAME" | mail -s "HA Event" admin@example.com
        # (Optional) Add MASTER specific actions here
        ;;
    "BACKUP")
        logger "Keepalived: BACKUP on $HOSTNAME DEBUG EDB"
        #echo "Keepalived: BACKUP on $HOSTNAME" | mail -s "HA Event" admin@example.com
        # (Optional) Add BACKUP specific actions here
        ;;
    "FAULT")
        logger "Keepalived: FAULT on $HOSTNAME DEBUG EDB"
        #echo "Keepalived: FAULT on $HOSTNAME" | mail -s "HA Event" admin@example.com
        # FAULT 상태일 때 Greenplum DB 중지 (sudoers 설정 필수)
        sudo -u gpadmin -i /usr/local/greenplum-db/bin/pg_ctl stop -D /data/coordinator/gpseg-1
        ;;
    "STOP")
        logger "Keepalived: STOPPED on $HOSTNAME DEBUG EDB"
        # (Optional) Add STOP specific actions here
        ;;
    *)
        # MASTER, BACKUP, FAULT, STOP 외의 알 수 없는 상태
        logger "Keepalived: Unknown state $CURRENT_STATE on $HOSTNAME"
        ;;
esac

exit 0
