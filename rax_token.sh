#!/bin/bash 
# This is a simple function for renewing your
# Rackspace public cloud token. Fill in ${USER}
# and ${API_KEY} with your information and
# source this script. The token is exported as
# ${TOKEN}.

USER=
API_KEY=

ENDPOINT=https://identity.api.rackspacecloud.com/v2.0/tokens
PAYLOAD="{\"auth\":{\"RAX-KSKEY:apiKeyCredentials\":{\"username\":\"${USER}\",\"apiKey\":\"${API_KEY}\"}}}"
HEADERS="Content-type: application/json"

# Check if a command is installed.
function is_command {
  local FAILURE

  for program in $@; do
    hash ${program} > /dev/null 2>&1
    if [ $? != 0 ]; then
      echo "Command not found: ${program}" >&2
      FAILURE='true'
    fi
  done

  if [ ! -z ${FAILURE} ]; then
    exit 127
  fi
}

is_command jq

export TOKEN=$(curl -s ${ENDPOINT} -d "${PAYLOAD}" -H "${HEADERS}" | jq --raw-output .[].token.id)
