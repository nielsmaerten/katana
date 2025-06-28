#!/bin/bash
# This script is called by cron every night. Check crontab -e
#############################################################

# Rclone arguments
LOGFILE="/var/log/rclone-sync-restic.log"
SRC="/tank/restic"
DEST="target-restic:"

# Webhook to send after success
SUCCESS_WEBHOOK="{{ rclone_sync_restic_url_success }}"
# Webhook to send after fail
FAIL_WEBHOOK="{{ rclone_sync_restic_url_fail }}"

# RCLONE command
RCLONE_CMD="/usr/bin/rclone sync '$SRC' '$DEST' --log-file '$LOGFILE' --log-level DEBUG && curl -d 'Restic Sync OK.' '$SUCCESS_WEBHOOK' > /dev/null || curl '$FAIL_WEBHOOK' > /dev/null"

# Get lock and run rclone
/usr/bin/flock /var/lock/rclone-sync.lock -c "$RCLONE_CMD"