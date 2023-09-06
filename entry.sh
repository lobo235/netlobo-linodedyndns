#!/bin/sh

# run command once at startup
echo "Container Started... running DNS check/update"
/bin/sh /updaterScript.sh

# start cron
echo "Starting Cron..."
/usr/sbin/crond -f -l 8
