#!/bin/bash

CTM_ENV=endpoint
#CTM_SERVER=[CTM_HOST]
#CTM_HOSTGROUP=app0
#PORT=7020
#DOCKER_HOST=
ALIAS=$DOCKER_HOST:$PORT/

echo delete or remove a controlm hostgroup [$CTM_HOSTGROUP] with controlm agent [$ALIAS]
ctm config server:hostgroup:agent::delete $CTM_SERVER $CTM_HOSTGROUP "$ALIAS" -e $CTM_ENV

echo unregister controlm remotehost [$ALIAS] with controlm [$CTM_SERVER], environment [$CTM_ENV] 
ctm config server:remotehost::delete $CTM_SERVER "$ALIAS"

exit 0
