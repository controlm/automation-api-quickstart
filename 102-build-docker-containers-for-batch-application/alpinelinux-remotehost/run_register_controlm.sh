#!/bin/bash

CTM_ENV=endpoint
#CTM_SERVER=[CTM_HOST]
#CTM_HOSTGROUP=app0
#PORT=7020
#DOCKER_HOST=
ALIAS=$DOCKER_HOST:$PORT

echo register controlm remotehost [$ALIAS] with controlm [$CTM_SERVER], environment [$CTM_ENV]
ctm config server:remotehost::add $CTM_SERVER "$ALIAS" $PORT -e $CTM_ENV

echo add or create a controlm hostgroup [$CTM_HOSTGROUP] with controlm agent [$ALIAS]
ctm config server:hostgroup:agent::add $CTM_SERVER $CTM_HOSTGROUP "$ALIAS" -e $CTM_ENV

# loop forever
#while true; do echo x && sleep 60; done

exit 0
