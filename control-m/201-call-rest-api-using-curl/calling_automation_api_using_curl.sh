#!/bin/bash

 
endpoint=                                                        # HTTP end point in the format of https://<controlmEndPoint>:8443/automation-api
user=                                                            # Set this variable to Controlm-M user credentials
password=                                                        # Set this variable to Controlm-M user credentials
curl_params=-k                                                   # Out Of the Box the end point comes with self signed certificate, -k option accept such certificates
 
# Session Login and get access API session token
login=$(curl $curl_params -s -H "Content-Type: application/json" -X POST -d "{\"username\":\"$username\",\"password\":\"$password\"}" "$endpoint/session/login" )
if [[ $login == *token* ]] ; then
	token=$(echo ${login##*token\" : \"} | cut -d '"' -f 1)
else
	printf "%s\n" "$login"
	printf "Login failed!\n"
	exit 1
fi
echo token=$token

# using curl to GET information
ctm=                                                            # set this variable to Control-m a server name
orderno=                                                        # set this variable to orderno of a specific job    
jobid=$ctm:$orderno
eventname=                                                      # set this variable to name of Event (Condition) to add/remove    

echo ctm=$ctm orderno=$orderno jobid=$jobid

curl $curl_params -H "Authorization: Bearer $token" "$endpoint/config/servers"                      # Get list of servers
curl $curl_params -H "Authorization: Bearer $token" "$endpoint/config/server/$ctm/hostgroups"       # Get list of hostgroups of a specific controlm
curl $curl_params -H "Authorization: Bearer $token" "$endpoint/run/jobs/status?limit=4&jobname=*"   # GET running jobs

echo Retriving information on job with jobid=$jobid                                                                                       # GET running job output/status/log
curl $curl_params -H "Authorization: Bearer $token" "$endpoint/run/job/$jobid/status"               # GET running job status     
curl $curl_params -H "Authorization: Bearer $token" "$endpoint/run/job/$jobid/log"                  # GET running job log    
curl $curl_params -H "Authorization: Bearer $token" "$endpoint/run/job/$jobid/output"               # GET running job output     

# using curl to Add/delete Event (Condition)
curl $curl_params -H "Authorization: Bearer $token" -H "Content-Type: application/json" -X POST -d "{\"name\": \"$eventname\",\"date\":\"0505\"}"  "$endpoint/run/event/$ctm"
curl $curl_params -H "Authorization: Bearer $token" -X DELETE "$endpoint/run/event/$ctm/$eventname/0505"

# using curl to build Jobs as code
curl $curl_params -H "Authorization: Bearer $token" -X POST  -F "definitionsFile=@../101-create-first-job-flow/AutomationAPISampleFlow.json" "$endpoint/build"


# Session Logout to invalidate API session token
curl $curl_params -H "Authorization: Bearer $token" -X POST  "$endpoint/session/logout"


