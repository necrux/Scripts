#!/bin/bash
#Enumerate all servers on your Rackspace cloud account and establish an SSH connection to one via a selection menu.

#Substitute with your Rackspace info.
USERNAME=
DDI=
API=

#Substituta with your SSH info.
SSH_USER=
SSH_PORT=
SSH_COMMAND=

clear
echo "~~~~~~Rackspace Server List Forthcoming~~~~~~"

TOKEN=$(curl -s \
-X 'POST' \
-d "{\"auth\":{\"RAX-KSKEY:apiKeyCredentials\":{\"username\":\"$USERNAME\", \"apiKey\":\"$API\"}}}" \
-H "Content-Type: application/json" \
https://identity.api.rackspacecloud.com/v2.0/tokens \
|python -m json.tool|grep -A5 token|awk -F\" '/id/ {print $4}')

SERVER_NAMES=($(for DC in dfw ord syd iad hkg; do curl -s https://$DC.servers.api.rackspacecloud.com/v2/$DDI/servers/detail -H "X-Auth-Token: $TOKEN" | python -m json.tool|grep '"name"'|awk -F\" '{print $4}'|sed 's/ /-/g'; done))

SERVER_IP=($(for DC in dfw ord syd iad hkg; do curl -s https://$DC.servers.api.rackspacecloud.com/v2/$DDI/servers/detail -H "X-Auth-Token: $TOKEN" | python -m json.tool|grep -A7 '"public"'|egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"; done))

count=1
server=0
choice=0

echo
for i in $(echo "${SERVER_NAMES[@]}")
do 
    echo -e "$count $i \t ${SERVER_IP[$server]}" && count=$((count + 1)) && server=$((server + 1))
done

echo -e "\nChoose your server!" 
read -p ",;-;, >>> " choice

until [ "$choice" -ge 1 -a "$choice" -le "$count" ] 2> /dev/null
do
    echo "$choice is not a valid entry. Please try again."
    echo -e "\nChoose your server!" 
    read -p ",;-;, >>> " choice
done

ssh -p$SSH_PORT $SSH_USER@${SERVER_IP[$((choice - 1))]}
