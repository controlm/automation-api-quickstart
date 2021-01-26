#!/bin/bash

 
endpoint=                                                        # HTTP end point in the format of https://<controlmEndPoint>:8443/automation-api
aapi_token=														 # Automation-Api token
curl_params=-k                                                   # Out Of the Box the end point comes with self signed certificate, -k option accept such certificates
 
# using curl to GET information
ctm=                                                            # set this variable to Control-m a server name
orderno=                                                        # set this variable to orderno of a specific job    
jobid=$ctm:$orderno
eventname=                                                      # set this variable to name of Event (Condition) to add/remove    

echo ctm=$ctm orderno=$orderno jobid=$jobid

curl $curl_params -H "x-api-key: $aapi_token" "$endpoint/config/servers"                      # Get list of servers
curl $curl_params -H "x-api-key: $aapi_token" "$endpoint/config/server/$ctm/hostgroups"       # Get list of hostgroups of a specific controlm
curl $curl_params -H "x-api-key: $aapi_token" "$endpoint/run/jobs/status?limit=4&jobname=*"   # GET running jobs

echo Retriving information on job with jobid=$jobid                                                                                       # GET running job output/status/log
curl $curl_params -H "x-api-key: $aapi_token" "$endpoint/run/job/$jobid/status"               # GET running job status     
curl $curl_params -H "x-api-key: $aapi_token" "$endpoint/run/job/$jobid/log"                  # GET running job log    
curl $curl_params -H "x-api-key: $aapi_token" "$endpoint/run/job/$jobid/output"               # GET running job output     

# using curl to Add/delete Event (Condition)
curl $curl_params -H "x-api-key: $aapi_token" -H "Content-Type: application/json" -X POST -d "{\"name\": \"$eventname\",\"date\":\"0505\"}"  "$endpoint/run/event/$ctm"
curl $curl_params -H "x-api-key: $aapi_token" -X DELETE "$endpoint/run/event/$ctm/$eventname/0505"

# using curl to build Jobs as code
curl $curl_params -H "x-api-key: $aapi_token" -X POST  -F "definitionsFile=@../101-create-first-job-flow/AutomationAPISampleFlow.json" "$endpoint/build"

