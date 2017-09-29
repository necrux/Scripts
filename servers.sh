#!/bin/bash
# Enumerate all servers on your Rackspace cloud account and
# establish an SSH connection to one via a selection menu.

# Fill in with your Rackspace info.
USERNAME=
DDI=
API=

# Fill in with your SSH info.
SSH_USER=
SSH_PORT=

Datacenters=(dfw ord syd iad hkg)

# Font color.
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
DEFAULT=$(tput setaf 9)
NF=$(tput sgr0) #No Formatting.

# Check if a command is installed.
function is_command {
  local FAILURE

  for program in $@; do
    hash ${program} > /dev/null 2>&1
    if [ $? != 0 ]; then
      echo "Command not found: ${program}"
      FAILURE='true'
    fi
  done

  if [ ! -z ${FAILURE} ]; then
    exit 127
  fi
}

function server_info {
  for DC in ${Datacenters[*]}; do
    curl -s https://${DC}.servers.api.rackspacecloud.com/v2/${DDI}/servers/detail -H "X-Auth-Token: ${TOKEN}" \
    | jq '.[][] | "\(.name) \(.accessIPv4)"'
  done
}

is_command jq

echo -e "${YELLOW}     ~~~~~~ Rackspace Server List Forthcoming ~~~~~~${NF}\n"

TOKEN=$(curl -s \
  -X "POST" \
  -d "{\"auth\":{\"RAX-KSKEY:apiKeyCredentials\":{\"username\":\"${USERNAME}\", \"apiKey\":\"${API}\"}}}" \
  -H "Content-Type: application/json" \
  https://identity.api.rackspacecloud.com/v2.0/tokens \
  | jq --raw-output .[].token.id)

SERVERS=$(server_info)

IFS=$'\n'
select server in ${SERVERS[@]}; do
  if [ ! -z "${server}" ]; then
    selection=${server}
    break
  else
    echo "Incorrect entry."
  fi
done

ssh -o StrictHostKeyChecking=no -p${SSH_PORT} ${SSH_USER}@$(echo ${selection} | grep -o "[0-9].*[0-9]")
