#!/bin/bash 

echo "parameters: $argv"
AG_NODE_ID=`hostname`
PERSISTENT_VOL=$1/$AG_NODE_ID
AAPI_USER=$3
AAPI_END_POINT=$2
AAPI_PASS=$4
CTM_SERVER_NAME=$5
FOLDERS_EXISTS=false
AGENT_REGISTERED=false
CTM_HOST_NAME=$6
export CONTROLM=/home/controlm/ctm
agentName=$(hostname)

# create if needed, and map agent persistent data folders
echo 'mapping persistent volume'
cd /home/controlm

sudo echo PATH="${PATH}:/home/controlm/bmcjava/bmcjava-V3/bin:/home/controlm/ctm/scripts:/home/controlm/ctm/exe">>~/.bash_profile
sudo echo export PATH>>~/.bash_profile

source ~/.bash_profile

if [ ! -d $PERSISTENT_VOL/pid ];
then
        echo 'first time the agent is using the persistent volume, moving folders to persistent volume'
        # no agent files exist in PV, copy the current agent files to PV
        mkdir $PERSISTENT_VOL
		mv $CONTROLM/backup $CONTROLM/capdef $CONTROLM/dailylog $CONTROLM/data $CONTROLM/measure $CONTROLM/onstmt $CONTROLM/pid $CONTROLM/procid $CONTROLM/status $CONTROLM/sysout $CONTROLM/temp $CONTROLM/cm -t $PERSISTENT_VOL
		

else
        echo 'this is not the first time an agent is running using this persistent volume, mapping folder to existing persistent volume'
        FOLDERS_EXISTS=true
		rm -Rf $CONTROLM/backup $CONTROLM/capdef $CONTROLM/dailylog $CONTROLM/data $CONTROLM/measure $CONTROLM/onstmt $CONTROLM/pid $CONTROLM/procid $CONTROLM/status $CONTROLM/sysout $CONTROLM/temp $CONTROLM/cm
		sed '/CM_LIST_SENT2CTMS/d' $PERSISTENT_VOL/data/CONFIG.dat
fi
# create link to persistent volume
ln -s $PERSISTENT_VOL/backup    $CONTROLM/backup
ln -s $PERSISTENT_VOL/capdef    $CONTROLM/capdef
ln -s $PERSISTENT_VOL/dailylog  $CONTROLM/dailylog
ln -s $PERSISTENT_VOL/data      $CONTROLM/data
ln -s $PERSISTENT_VOL/measure   $CONTROLM/measure
ln -s $PERSISTENT_VOL/onstmt    $CONTROLM/onstmt
ln -s $PERSISTENT_VOL/pid       $CONTROLM/pid
ln -s $PERSISTENT_VOL/procid    $CONTROLM/procid
ln -s $PERSISTENT_VOL/sysout    $CONTROLM/sysout
ln -s $PERSISTENT_VOL/status    $CONTROLM/status
ln -s $PERSISTENT_VOL/temp      $CONTROLM/temp
ln -s $PERSISTENT_VOL/cm        $CONTROLM/cm



# echo using new AAPI configuration, not the default build time configuration
ctm env add ctm_env $AAPI_END_POINT $AAPI_USER $AAPI_PASS
ctm env set ctm_env

# check if Agent exists in the Control-M Server
if $FOLDERS_EXISTS ; then
       ctm config server:agents::get $CTM_SERVER_NAME $AG_NODE_ID | grep $AG_NODE_ID
       if [[ $? == "0" ]] ;  then
	       echo 'agent already exists'
               AGENT_REGISTERED=true
       fi
fi

if $FOLDERS_EXISTS && $AGENT_REGISTERED ; then
               # start the Agent
               echo 'starting the Agent'
               start-ag -u controlm -p ALL
               else
               echo 'configuring and registering the agent'
               ctm provision agent::setup $CTM_SERVER_NAME $AG_NODE_ID 7006 -f agent_configuration.json
		
fi


echo 'checking Agent communication with Control-M Server'
ag_diag_comm

echo 'adding the Agent to Host Group'
ctm config server:hostgroup:agent::add $CTM_SERVER_NAME $CTM_HOST_NAME $AG_NODE_ID


echo 'deploying agent to KUBERNETES ai job type'
x=1
ctm deploy ai:jobtype  $CTM_SERVER_NAME $agentName KUBERNETES | grep "successful" > res.txt

while [ ! -s res.txt ]
do
   echo "try $x times"
   #ctm deploy ai:jobtype  $CTM_SERVER_NAME $agentName KUBERNETES
   ctm deploy ai:jobtype  $CTM_SERVER_NAME $agentName KUBERNETES | grep "successful" > res.txt
	x=$(( $x + 1 ))
   sleep 20
done

echo 'deploying agent to KUBERNETES ai job type successed'
rm res.txt

echo 'running in agent container and keeping it alive'
./ctmhost_keepalive.sh


