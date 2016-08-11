#!/usr/bin/env bash

trap 'exit 0' SIGTERM

CTM_ENV=endpoint
CTM_SERVER=[CTM_HOST]
#CTM_HOSTGROUP=app1 
#CTM_AGENT_PORT=7020
CTM_AGENT_ALIAS=$(hostname):$CTM_AGENT_PORT

cd
source .bash_profile

echo run and register controlm agent [$CTM_AGENT_ALIAS] with controlm [$CTM_SERVER], environment [$CTM_ENV] 
ctm provision setup $CTM_SERVER $CTM_AGENT_ALIAS $CTM_AGENT_PORT -e $CTM_ENV

echo add or create a controlm hostgroup [$CTM_HOSTGROUP] with controlm agent [$CTM_AGENT_ALIAS]
ctm config server:hostgroup:agent::add $CTM_SERVER $CTM_HOSTGROUP $CTM_AGENT_ALIAS -e $CTM_ENV

# loop forever
while true; do echo x && sleep 60; done

exit 0

