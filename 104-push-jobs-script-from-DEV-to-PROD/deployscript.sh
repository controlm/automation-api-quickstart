#! /bin/bash

# PROD
prodEndPoint=https://<endpoint server>:8443/automation-api
prodUser=apiuser 
prodPasswd=empass 
deploydescriptor_path=/cygdrive/c/DeployDescriptorPROD.json 
Temp_JobDef_path=/cygdrive/c/temp_job_file.json

#Dev
devEndPoint=https://<enpoint server>:8443/automation-api
devUser=apiuser 
devPasswd=empass 

# Login to automation API and start a session on Dev# 
devLogin=$(curl -s --insecure --header "Content-Type: application/json" --request POST --data "{\"username\":\"$devUser\",\"password\":\"$devPasswd\"}" "$devEndPoint/session/login") 

# Extract the token ID from session details from Dev# 
devToken=$(echo ${devLogin##*token\" : \"} | cut -d '"' -f 1)
echo $devToken

# Download the job definitions and save on json#
tmp=$(curl -k -H "Authorization: Bearer $devToken" "Content-Type: application/json" "$devEndPoint/deploy/jobs?ctm=*&folder=Dev_Aud*")

echo -e $tmp | sed 's/\\"/"/g;s/"{/{/;s/}"/}/' > /cygdrive/c/temp_job_file.json

curl --insecure --header "Authorization: Bearer $devToken" --request POST --data "{\"username\":\"$devUser\",\"token\":\"$devToken\"}" "$devEndPoint/session/logout"

# Login to automation API and start a session on PROD# 
PRODlogin=$(curl -s --insecure --header "Content-Type: application/json" --request POST --data "{\"username\":\"$prodUser\",\"password\":\"$prodPasswd\"}" "$prodEndPoint/session/login") 

# Extract the token ID from session details from PROD# 
PRODtoken=$(echo ${PRODlogin##*token\" : \"} | cut -d '"' -f 1)
echo $PRODtoken

# dynamic job def to transform and deploy#
curl -k -H "Authorization: Bearer $PRODtoken" -X POST -F "definitionsFile=@$Temp_JobDef_path" -F "deployDescriptorFile=@$deploydescriptor_path" "$prodEndPoint/deploy" 

# Log out from the session#
curl --insecure --header "Authorization: Bearer $PRODtoken" --request POST --data "{\"username\":\"$prodUser\",\"token\":\"$token\"}" "$prodEndPoint/session/logout"

# Clean up temp file#
rm -f $Temp_JobDef_path