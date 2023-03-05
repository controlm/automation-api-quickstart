#!/bin/bash
cd "$(dirname "$0")"
echo "Configures Agent container"

echo "Install K8s certificates for AI server"
export CONTROLM=/home/controlm/ctm
PEM_FILE=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
KEYSTORE=$CONTROLM/cm/AI/data/security/apcerts
KSPASS=appass

NUM_CERTS=$(grep -c 'END CERTIFICATE' $PEM_FILE)

for N in $(seq 0 $((NUM_CERTS - 1))); do
  awk "n==$N { print }; /END CERTIFICATE/ { n++ }" $PEM_FILE |
    keytool -noprompt -import -trustcacerts -alias "kube-pod-ca-$N" -keystore "$KEYSTORE" -storepass $KSPASS
done

echo "Parameters: $argv"
AG_NODE_ID=$(hostname)
PERSISTENT_VOL=$1/$AG_NODE_ID
AAPI_END_POINT=$2
AAPI_TOKEN=$3
AGENT_TOKEN_TAG=$4
CTM_SERVER_NAME=IN01
CTM_HOSTGROUP_NAME=$5
FOLDERS_EXISTS=false
AGENT_REGISTERED=false

# create if needed, and map agent persistent data folders
echo 'Mapping persistent volume'
source ~/.bash_profile

if [ ! -d "$PERSISTENT_VOL"/pid ]; then
  echo "Persistent connection : internal AR keep-alive"
  {
    echo "AR_PING_TO_SERVER_IND Y"
    echo "AR_PING_TO_SERVER_INTERVAL 30"
    echo "AR_PING_TO_SERVER_TIMEOUT 60"
    echo "DISABLE_CM_SHUTDOWN Y"
  } >>~/ctm/data/CONFIG.dat
  touch ~/ctm/data/DISABLE_CM_SHUTDOWN_Y.cfg

  echo "Update Agent configuration file with current hostname"
  ctmcfg -table CONFIG -action update -parameter INSTALL_HOSTNAME -value "${AG_NODE_ID}"
  ctmcfg -table CONFIG -action update -parameter LOCALHOST -value "${AG_NODE_ID}"
  ctmcfg -table CONFIG -action update -parameter PHYSICAL_UNIQUE_AGENT_NAME -value "${AG_NODE_ID}"

  # no agent files exist in PV, copy the current agent files to PV
  echo 'first time the agent is using the persistent volume, moving folders to persistent volume'
  mkdir "$PERSISTENT_VOL"
  mv $CONTROLM/backup $CONTROLM/capdef $CONTROLM/dailylog $CONTROLM/data $CONTROLM/measure $CONTROLM/onstmt $CONTROLM/pid $CONTROLM/procid $CONTROLM/status $CONTROLM/sysout $CONTROLM/temp $CONTROLM/cm -t "$PERSISTENT_VOL"
else
        echo 'this is not the first time an agent is running using this persistent volume, mapping folder to existing persistent volume'
        FOLDERS_EXISTS=true
		rm -Rf $CONTROLM/backup $CONTROLM/capdef $CONTROLM/dailylog $CONTROLM/data $CONTROLM/measure $CONTROLM/onstmt $CONTROLM/pid $CONTROLM/procid $CONTROLM/status $CONTROLM/sysout $CONTROLM/temp $CONTROLM/cm
  sed '/CM_LIST_SENT2CTMS/d' "$PERSISTENT_VOL"/data/CONFIG.dat
fi
# create link to persistent volume
ln -s "$PERSISTENT_VOL"/backup $CONTROLM/backup
ln -s "$PERSISTENT_VOL"/capdef $CONTROLM/capdef
ln -s "$PERSISTENT_VOL"/dailylog $CONTROLM/dailylog
ln -s "$PERSISTENT_VOL"/data $CONTROLM/data
ln -s "$PERSISTENT_VOL"/measure $CONTROLM/measure
ln -s "$PERSISTENT_VOL"/onstmt $CONTROLM/onstmt
ln -s "$PERSISTENT_VOL"/pid $CONTROLM/pid
ln -s "$PERSISTENT_VOL"/procid $CONTROLM/procid
ln -s "$PERSISTENT_VOL"/sysout $CONTROLM/sysout
ln -s "$PERSISTENT_VOL"/status $CONTROLM/status
ln -s "$PERSISTENT_VOL"/temp $CONTROLM/temp
ln -s "$PERSISTENT_VOL"/cm $CONTROLM/cm

echo "Using new AAPI configuration, not the default build time configuration"
ctm env add ctm_env "$AAPI_END_POINT" "$AAPI_TOKEN"
ctm env set ctm_env

echo "Check if Agent exists in the Control-M Server"
if $FOLDERS_EXISTS ; then
  ctm config server:agents::get "$CTM_SERVER_NAME" "$AG_NODE_ID" | grep "$AG_NODE_ID"
       if [[ $? == "0" ]] ;  then
	       echo 'agent already exists'
               AGENT_REGISTERED=true
       fi
fi

if $FOLDERS_EXISTS && $AGENT_REGISTERED ; then
  echo 'Starting the Agent'
               start-ag -u controlm -p ALL
else
  echo 'Configuring and registering the agent'
  ctm provision saas:agent::setup $AGENT_TOKEN_TAG $AG_NODE_ID
fi

echo 'Checking Agent communication with Control-M Server'
ag_ping
ag_diag_comm

echo 'Adding the Agent to Host Group'
ctm config server:hostgroup:agent::add "$CTM_SERVER_NAME" "$CTM_HOSTGROUP_NAME" "$AG_NODE_ID"

echo 'Deploying Control-M/Integration Kubernetes Job Type to Control-M/Agent'
ctm deploy ai:jobtype IN01 "$AG_NODE_ID" KUBERNETES | grep "successful" >res.txt

x=1
while [[ ! -s res.txt && $x -lt 20 ]]; do
  echo "attempt #$x"
  ctm deploy ai:jobtype IN01 "$AG_NODE_ID" KUBERNETES | grep "successful" >res.txt
  x=$((x + 1))
  sleep 20
done

if [[ $x -lt 20 ]]; then
  echo 'Deploying Control-M/Integration Kubernetes Job Type to Control-M/Agent successes'
else
  echo 'Deploying Control-M/Integration Kubernetes Job Type to Control-M/Agent failed'
fi
rm res.txt

echo 'KUBERNETES AI Job Type is ready for use'
bash ./ctmhost_keepalive.sh