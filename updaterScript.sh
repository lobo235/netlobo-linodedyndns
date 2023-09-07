#!/bin/sh
# Modified by Justin Barlow (https://github.com/lobo235) on 09/06/2023
# Goal is to host this in a docker container with built-in 10-minute check loop to run in my home lab Nomad cluster

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
# DOMAIN_NAME=
# A_RECORD=

# Optional Environment variables
CHECK_FREQUENCY_SECS=600 # (defaults to 10 minutes)

function resource_update {
curl -s -H "Content-Type: application/json" \
	-H "Authorization: Bearer ${LINODE_API_KEY}" \
	-X PUT -d '{
		"type": "A",
		"name": "'${A_RECORD}'",
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

function match_linode_records {
	DOMAIN_ID=$(curl -s -H "Authorization: Bearer ${LINODE_API_KEY}" https://api.linode.com/v4/domains/ | jq -r ".data[] | select(.domain==\"${DOMAIN_NAME}\") | .id")
	if [ ${DOMAIN_ID} -gt 0 ]; then
		log "Domain name ${DOMAIN_NAME} was found with ID ${DOMAIN_ID}"
	else
		log "Domain name ${DOMAIN_NAME} was not found in the Linode account. Check the spelling or make sure the LINODE_API_KEY is correct"
		exit 1
	fi
	RESOURCE_ID=$(curl -s -H "Authorization: Bearer $LINODE_API_KEY" https://api.linode.com/v4/domains/$DOMAIN_ID/records/ | jq ".data[] | select(.type==\"A\" and .name==\"${A_RECORD}\") | .id")
	if [ ${RESOURCE_ID} -gt 0 ]; then
		log "DNS A record with name ${A_RECORD} was found with ID ${RESOURCE_ID}"
	else
		log "DNS A record with name ${A_RECORD} was not found in the ${DOMAIN_NAME} domain. Check the spelling or make sure the A record actually exists"
		exit 1
	fi
}

match_linode_records
WAN_IP=$(curl -s icanhazip.com)
LINODE_IP=$(curl -s -H "Authorization: Bearer ${LINODE_API_KEY}" https://api.linode.com/v4/domains/${DOMAIN_ID}/records/${RESOURCE_ID} | jq -r ".target")
echo $WAN_IP > ${HOME}/wan_ip.txt

if [ "${WAN_IP}" = "${LINODE_IP}" ]; then
	log "Current WAN IP (${WAN_IP}) matches Linode DNS record for ${A_RECORD}. Will check again every 10 minutes..."
else
	log "Current WAN IP (${WAN_IP}) differs from the Linode DNS record (${LINODE_IP}) for ${A_RECORD}. Results from Linode are displayed below:" 
	resource_update | jq -M
	echo
fi

while true
do
	sleep ${CHECK_FREQUENCY_SECS}
	check_wan
done