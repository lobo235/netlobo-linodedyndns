#!/bin/sh
# Modified by Justin Barlow (https://github.com/lobo235) on 09/06/2023
# Goal is to host this in a docker container with built-in 5-minute check loop to run in my home lab Nomad cluster

# This script update is based on information found here: https://www.linode.com/docs/api/domains/#domain-record-update

# You first must find out the domain ID and resource ID numbers. In order to do this follow the steps below.
# 1. Create a Linode API Key through your account profile at https://cloud.linode.com/profile/tokens. Give it rights to read/write to domains only.
# 2. From a shell run the following command: LINODE_API_KEY=[insert API key from step 1 here]
# 3. Run the following command to get the domain ID number for the domain you want to manage: curl -H "Authorization: Bearer $LINODE_API_KEY" https://api.linode.com/v4/domains/
# 4. From a shell run the following command: DOMAIN_ID=[insert domain ID number from step 3 here]
# 5. Run the following command to get the resource ID number for the subdomain you want to manage: curl -H "Authorization: Bearer $LINODE_API_KEY" https://api.linode.com/v4/domains/$DOMAIN_ID/records/
# 6. From a shell run the following command: RESOURCE_ID=[insert resource ID number from step 5 here]
# 7. Run the following command to verify the current settings for this resource: curl -H "Authorization: Bearer $LINODE_API_KEY" https://api.linode.com/v4/domains/$DOMAIN_ID/records/$RESOURCE_ID
# 8. Use the information collected from these commands to complete the variables below in this script.

# Environment variables needed by the container
# LINODE_API_KEY=
# DOMAIN_ID=
# RESOURCE_ID=
# NAME=

function resource_update {
curl -s -H "Content-Type: application/json" \
	-H "Authorization: Bearer ${LINODE_API_KEY}" \
	-X PUT -d '{
		"type": "A",
		"name": "'${NAME}'",
		"target": "'${WAN_IP}'",
		"priority": 0,
		"weight": 0,
		"port": 0,
		"service": null,
		"protocol": null,
		"ttl_sec": 120,
		"tag": null
	}' \
	https://api.linode.com/v4/domains/${DOMAIN_ID}/records/${RESOURCE_ID}
}

function log {
	echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1"
}

function check_wan {
WAN_IP=$(curl -s icanhazip.com)
if [ -f ${HOME}/wan_ip.txt ]; then
	OLD_WAN_IP=$(cat ${HOME}/wan_ip.txt)
else
	log "No file, need IP"
	OLD_WAN_IP=""
fi

if [ "${WAN_IP}" = "${OLD_WAN_IP}" ]; then
	log "IP Unchanged"
else
	echo ${WAN_IP} > ${HOME}/wan_ip.txt
	log "IP Changed! Updating Linode DNS to ${WAN_IP}. Results from Linode are displayed below."
	resource_update | jq -M
	echo
fi
}

WAN_IP=$(curl -s icanhazip.com)
LINODE_IP=$(curl -s -H "Authorization: Bearer ${LINODE_API_KEY}" https://api.linode.com/v4/domains/${DOMAIN_ID}/records/${RESOURCE_ID} | jq -r ".target")
echo $WAN_IP > ${HOME}/wan_ip.txt

if [ "${WAN_IP}" = "${LINODE_IP}" ]; then
	log "Current WAN IP (${WAN_IP}) matches Linode DNS record for ${NAME}. Will check again in 5 minutes..."
else
	log "Current WAN IP (${WAN_IP}) differs from the Linode DNS record (${LINODE_IP}) for ${NAME}. Results from Linode are displayed below:" 
	resource_update | jq -M
	echo
fi

while true
do
	check_wan
	sleep 600
done