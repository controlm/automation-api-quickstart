#!/bin/bash
#use agent's java for provision setup
PATH=$PATH:~/bmcjava/bmcjava-V2/bin
CTM_ENV=endpoint
UNIQUE=$(head /dev/urandom | tr -dc A-Za-z | head -c 6 ; echo '')
AGENT_NAME=$(hostname)-$UNIQUE

cd
pwd

echo run and register controlm agent [$AGENT_NAME] with controlm IN01, environment [$CTM_ENV] 
ctm provision saas:agent::setup $AGENT_TAG $AGENT_NAME -e $CTM_ENV
if [ $? -ne 0 ]; then
    echo "Error registering agent $AGENT_NAME (tag:$AGENT_TAG) in Control-M/Server"
	exit 1
fi

echo add or create a controlm hostgroup [$CTM_HOSTGROUP] with controlm agent [$AGENT_NAME]
ctm config server:hostgroup:agent::add IN01 $CTM_HOSTGROUP $AGENT_NAME -e $CTM_ENV
if [ $? -ne 0 ]; then
    echo "Error adding agent $AGENT_NAME to agent host group $CTM_HOSTGROUP"
	exit 1
fi

# loop forever
sleep infinity
exit 0
 