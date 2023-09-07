#!/bin/sh

function log {
	echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1"
}

# run command once at startup
log "Container Started... running DNS check/update loop"
/bin/sh /updaterScript.sh
