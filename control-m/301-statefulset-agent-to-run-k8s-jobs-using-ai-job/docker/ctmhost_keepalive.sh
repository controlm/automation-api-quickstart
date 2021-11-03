#!/bin/bash

source ~/.bashrc
echo checking Agent communication with Control-M Server
ag_diag_comm
ctmaggetcm

# ag_ping Loop control variables
# LIMIT is number of times to check HOSTS before timing out in error
LIMIT=5
# SLEEPTIME is nmber of seconds to sleep between successive pings to CURRENT_HOST
SLEEPTIME=120
COUNTER=0

# Create the HOSTS array
HOSTS=( $( grep CTMPERMHOSTS $CONTROLM/data/CONFIG.dat | awk '{ print $2 }' | tr '|' ' ' ) )
IFS='|'
OIFS=$IFS
for h in $PERM_HOSTS;
do
        HOSTS+=($h)
done
IFS=$OIFS

# Begin the main ag_ping loop
until [[ "${COUNTER}" -eq "${LIMIT}" ]]
do
        CURRENT_HOST=$(grep "CTMSHOST" $CONTROLM/data/CONFIG.dat | awk '{print $2}')
        printf '%s %s\n' "$(date)" "Current Host is $CURRENT_HOST"
        NEW_HOST=""

        ag_diag_comm
        ag_ping > /dev/null 2>&1
        # If ag_ping fails check other HOSTS
        if [[ $? -gt 0 ]];
        then
                printf '%s %s\n' "$(date)" "Error: ag_ping to $CURRENT_HOST failed!"
                for NEXT_HOST in ${HOSTS[@]};
                do
                        if [[ "$CURRENT_HOST" != "$NEXT_HOST" ]];
                        then
                                printf '%s %s\n' "$(date)" "Switching to Host $NEXT_HOST"
                                sed -i -e "/CTMSHOST/s/$CURRENT_HOST/$NEXT_HOST/" $CONTROLM/data/CONFIG.dat
                                ag_diag_comm
                                sleep 5
                                ag_ping > /dev/null 2>&1
                                sleep 5
                                ag_ping > /dev/null 2>&1
                                if [[ $? -gt 0 ]]
                                then
                                        printf '%s %s\n' "$(date)" "Error: ag_ping to $NEXT_HOST failed!"
                                        continue
                                else
                                        printf '%s %s\n' "$(date)" "New Host is $NEXT_HOST"
                                        #reset the timeout counter
                                        COUNTER=0
                                        NEW_HOST=$NEXT_HOST
                                        break
                                fi
                        fi
                done
                if [[ -z "${NEW_HOST}" ]];
                then
                        #increase the timeout counter
                        COUNTER=$((COUNTER+1))
                        #reset back to current_host
                        printf '%s %s\n' "$(date)" "All connections to PERM_HOSTS failed.  Resetting to $CURRENT_HOST $COUNTER time"
                        sed -i -e "/CTMSHOST/s/$NEXT_HOST/$CURRENT_HOST/" $CONTROLM/data/CONFIG.dat
                        ag_diag_comm
                        sleep 5
                        ag_ping > /dev/null 2>&1
                fi
        else
                COUNTER=0
                printf '%s %s\n' "$(date)" "Connected to $CURRENT_HOST"
                sleep $SLEEPTIME
        fi
done

# We have reached our LIMIT number of tries.  Agent cannot find a HOST. Alerting and abort
printf '%s %s\n' "$(date)" "Error: Timed out trying to connect to a CTM Host - aborting"
exit 99
