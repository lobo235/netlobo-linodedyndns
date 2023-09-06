# netlobo-linodedyndns
Linode Dynamic DNS Updater

## Required Environment Variables:
* LINODE_API_KEY (Generate this in your Linode account)
* DOMAIN_ID (list the domains using the API to get the ID for the domain you'll be updating)
* RESOURCE_ID (get this by listing the records associated with the DOMAIN_ID above)
* NAME (the name of A Record to update with your WAN IP)

## More detailed instructions:
```
You first must find out the domain ID and resource ID numbers. In order to do this follow the steps below.
1. Create a Linode API Key through your account profile at https://cloud.linode.com/dashboard. Give it rights to read/write to domains only.
2. From a shell run the following command: LINODE_API_KEY=[insert API key from step 1 here]
3. Run the following command to get the domain ID number for the domain you want to manage: curl -H "Authorization: Bearer $LINODE_API_KEY" https://api.linode.com/v4/domains/
4. From a shell run the following command: DOMAIN_ID=[insert domain ID number from step 3 here]
5. Run the following command to get the resource ID number for the subdomain you want to manage: curl -H "Authorization: Bearer $LINODE_API_KEY" https://api.linode.com/v4/domains/$DOMAIN_ID/records/
6. From a shell run the following command: RESOURCE_ID=[insert resource ID number from step 5 here]
7. Run the following command to verify the current settings for this resource: curl -H "Authorization: Bearer $LINODE_API_KEY" https://api.linode.com/v4/domains/$DOMAIN_ID/records/$RESOURCE_ID
8. Use the information collected from these commands to complete the variables below in this script.
```
