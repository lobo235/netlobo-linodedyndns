# netlobo-linodedyndns
Linode Dynamic DNS Updater docker container. Using a provided Linode API token, this container will keep a DNS `A Record` up-to-date with your WAN IP. By default, it will check your WAN IP every 10 minutes and only update Linode's DNS record if the WAN IP changes.

## Prerequisites
* A Linode Account with a Domain name hosted in that account
* An existing `A Record` entry for the Domain

## Required Environment Variables:
* `LINODE_API_KEY` - Generate this in your Linode account
* `DOMAIN_NAME` - the name of the domain managed in your Linode account
* `A_RECORD` - the name of the A Record to update with your WAN IP

## Optional Environment Variables:
* `WAN_IP_PROVIDER` - Must only return the IP address, no html or extra stuff! (Defaults to ipv4.icanhazip.com)
* `CHECK_FREQUENCY_SECS` - Number of seconds to wait between WAN IP checks. Defaults to 600 (10 minutes)

## Setup

To set up the Linode Dynamic DNS Updater, follow these steps:

1. Create a Linode API Key through your account profile at [https://cloud.linode.com/dashboard](https://cloud.linode.com/dashboard). Give it rights to read/write to domains only.
2. Run the docker container using your orchestrator of choice (I prefer HashiCorp's Nomad)

By following these steps, you will be able to keep your Linode DNS `A Record` up-to-date with your WAN IP, ensuring seamless connectivity to your domain.
