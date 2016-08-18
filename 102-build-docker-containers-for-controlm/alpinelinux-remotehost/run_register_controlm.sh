#!/bin/bash

CTM_ENV=endpoint
#CTM_SERVER=[CTM_HOST]
#CTM_HOSTGROUP=app0
#CTM_REMOTHOST_ALIAS=rh
#$(hostname):$CTM_AGENT_PORT

cd
source .bash_profile

echo run and register controlm remotehost [$CTM_REMOTHOST_ALIAS] with controlm [$CTM_SERVER], environment [$CTM_ENV] 
ctm provision setup $CTM_SERVER $CTM_AGENT_ALIAS $CTM_AGENT_PORT -e $CTM_ENV

echo add or create a controlm hostgroup [$CTM_HOSTGROUP] with controlm agent [$CTM_AGENT_ALIAS]
ctm config server:hostgroup:agent::add $CTM_SERVER $CTM_HOSTGROUP $CTM_AGENT_ALIAS -e $CTM_ENV

# loop forever
while true; do echo x && sleep 60; done

exit 0

