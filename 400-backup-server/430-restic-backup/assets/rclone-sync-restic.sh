#!/bin/bash
# This script is called by cron every night. Check crontab -e
#############################################################

# Rclone arguments
LOGFILE="/var/log/rclone-sync-restic.log"
SRC="/tank/restic"
DEST="target-restic:"

# Webhook to send after success
SUCCESS_WEBHOOK="https://example.com/webhook/success"

# RCLONE command
RCLONE_CMD="/usr/bin/rclone sync '$SRC' '$DEST' --log-file '$LOGFILE' --log-level DEBUG && curl '$SUCCESS_WEBHOOK' > /dev/null"

# Get lock and run rclone
/usr/bin/flock /var/lock/rclone-sync.lock -c "$RCLONE_CMD"