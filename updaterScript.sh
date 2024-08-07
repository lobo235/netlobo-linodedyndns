#!/bin/sh
# Modified by Justin Barlow (https://github.com/lobo235) on 09/06/2023
# Goal is to host this in a docker container with built-in check loop to run in my home lab Nomad cluster

# This script is based on information found here: https://www.linode.com/docs/api/domains/#domain-record-update

# Prerequisites
# A Linode Account with a Domain name hosted in that account
# Create an existing 'A Record' entry for the Domain

# Environment variables needed by the container
# LINODE_API_KEY=          # Linode API key
# DOMAIN_NAME=             # Domain name
# A_RECORD=                # A record name

[ -z "${LINODE_API_KEY}" ] && echo "No LINODE_API_KEY was provided, exiting!" && exit 1 || echo "LINODE_API_KEY was provided (starts with ${LINODE_API_KEY:0:5}...)"
echo "Configured DOMAIN_NAME is ${DOMAIN_NAME}"
echo "Configured A_RECORD is ${A_RECORD}"

# Optional Environment variables
[ -z "${WAN_IP_PROVIDER}" ] && WAN_IP_PROVIDER="ipv4.icanhazip.com" || WAN_IP_PROVIDER=${WAN_IP_PROVIDER}
echo "Configured WAN_IP_PROVIDER is ${WAN_IP_PROVIDER}"
[ -z "${CHECK_FREQUENCY_SECS}" ] && CHECK_FREQUENCY_SECS="600" || CHECK_FREQUENCY_SECS=${CHECK_FREQUENCY_SECS}
echo "Configured CHECK_FREQUENCY_SECS is ${CHECK_FREQUENCY_SECS}"

# Function to update the Linode DNS record
update_dns_record() {
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

# Function to log messages with timestamp
log() {
	echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1"
}

# Function to check the WAN IP and update the Linode DNS record if it has changed
check_wan_ip() {
	WAN_IP=$(curl -s ${WAN_IP_PROVIDER})
	if [ $? -eq 0 ]; then
		if [ -f ${HOME}/wan_ip.txt ]; then
			OLD_WAN_IP=$(cat ${HOME}/wan_ip.txt)
		else
			OLD_WAN_IP=""
		fi

		if [ "${WAN_IP}" = "${OLD_WAN_IP}" ]; then
			log "IP Unchanged"
		else
			echo ${WAN_IP} > ${HOME}/wan_ip.txt
			log "IP Changed! Updating Linode DNS to ${WAN_IP}. Results from Linode are displayed below."
			update_dns_record | jq -M
			echo
		fi
	else
		log "Request to ${WAN_IP_PROVIDER} failed! Is the internet connection down?"
	fi
}

# Function to match the Linode records with the provided domain and A record
match_linode_records() {
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

# Match the Linode records with the provided domain and A record
match_linode_records

# Get the current WAN IP and Linode DNS record IP
WAN_IP=$(curl -s ${WAN_IP_PROVIDER})
LINODE_IP=$(curl -s -H "Authorization: Bearer ${LINODE_API_KEY}" https://api.linode.com/v4/domains/${DOMAIN_ID}/records/${RESOURCE_ID} | jq -r ".target")
echo $WAN_IP > ${HOME}/wan_ip.txt

# Compare the WAN IP with the Linode DNS record IP
if [ "${WAN_IP}" = "${LINODE_IP}" ]; then
	log "Current WAN IP (${WAN_IP}) matches Linode DNS record for ${A_RECORD}. Will check again every ${CHECK_FREQUENCY_SECS} seconds..."
else
	log "Current WAN IP (${WAN_IP}) differs from the Linode DNS record (${LINODE_IP}) for ${A_RECORD}. Results from Linode are displayed below:" 
	update_dns_record | jq -M
	echo
fi

# Continuously check the WAN IP and update the Linode DNS record if it has changed
while true
do
	sleep ${CHECK_FREQUENCY_SECS}
	check_wan_ip
done
