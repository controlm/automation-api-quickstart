#! /bin/bash

# PROD
prodEndPoint=https://<servername for example customer-aapi.us.ctmsaas.com>/automation-api  
prodAapiToken=<Automation-Api token> 
deploydescriptor_path=/cygdrive/c/DeployDescriptorPROD.json 
Temp_JobDef_path=/cygdrive/c/temp_job_file.json

#Dev
devEndPoint=https://<servername for example customer-aapi.us.ctmsaas.com>/automation-api  
devAapiToken=<Automation-Api token> 

# Download the job definitions and save on json#
tmp=$(curl -k -H "x-api-key: $devAapiToken" "Content-Type: application/json" "$devEndPoint/deploy/jobs?ctm=*&folder=Dev_Aud*")

echo -e $tmp | sed 's/\\"/"/g;s/"{/{/;s/}"/}/' > /cygdrive/c/temp_job_file.json

# dynamic job def to transform and deploy#
curl -k -H "x-api-key: $prodAapiToken" -X POST -F "definitionsFile=@$Temp_JobDef_path" -F "deployDescriptorFile=@$deploydescriptor_path" "$prodEndPoint/deploy" 

# Clean up temp file#
rm -f $Temp_JobDef_path