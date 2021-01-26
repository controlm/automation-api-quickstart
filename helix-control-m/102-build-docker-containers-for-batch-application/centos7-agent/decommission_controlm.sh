#!/bin/bash

CTM_ENV=endpoint
AGENT_NAME=$(hostname)


cd
#source .bash_profile

echo remove agent [$AGENT_NAME] from hostgroup [$CTM_HOSTGROUP] 
ctm config server:hostgroup:agent::delete IN01 $CTM_HOSTGROUP $AGENT_NAME -e $CTM_ENV
if [ $? -ne 0 ]; then
    echo "Error deleting agent $AGENT_NAME from hostgroup $CTM_HOSTGROUP"
	exit 1
fi

echo unregister controlm agent [$AGENT_NAME] from server IN01 
ctm config server:agent::delete IN01 $AGENT_NAME -e $CTM_ENV
if [ $? -ne 0 ]; then
    echo "Error deleting agent $AGENT_NAME from the system"
	exit 1
fi

exit 0
