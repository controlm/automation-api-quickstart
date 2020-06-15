#!/bin/bash
#use agent's java for provision setup
PATH=$PATH:~/ctm/JRE_1.8/bin
CTM_ENV=endpoint
#CTM_SERVER=[CTM_HOST]
#CTM_HOSTGROUP=app0
#CTM_AGENT_PORT=7020
ALIAS=$(hostname):$CTM_AGENT_PORT

#cd
#source .bash_profile

echo run and register controlm agent [$ALIAS] with controlm [$CTM_SERVER], environment [$CTM_ENV] 
ctm provision setup $CTM_SERVER $ALIAS $CTM_AGENT_PORT -e $CTM_ENV

echo add or create a controlm hostgroup [$CTM_HOSTGROUP] with controlm agent [$ALIAS]
ctm config server:hostgroup:agent::add $CTM_SERVER $CTM_HOSTGROUP $ALIAS -e $CTM_ENV

# loop forever
while true; do echo x && sleep 60; done

exit 0
