#!/bin/bash

CTM_ENV=endpoint
#CTM_SERVER=[CTM_HOST]
#CTM_HOSTGROUP=app1 
#CTM_AGENT_PORT=7020
ALIAS=$(hostname):$CTM_AGENT_PORT/

#cd
#source .bash_profile

echo delete or remove a controlm hostgroup [$CTM_HOSTGROUP] with controlm agent [$ALIAS]
ctm config server:hostgroup:agent::delete $CTM_SERVER $CTM_HOSTGROUP $ALIAS -e $CTM_ENV

echo stop and unregister controlm agent [$ALIAS] with controlm [$CTM_SERVER], environment [$CTM_ENV] 
ctm config server:agent::delete $CTM_SERVER $ALIAS

exit 0
